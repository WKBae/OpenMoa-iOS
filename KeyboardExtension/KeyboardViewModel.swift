import Foundation
import SwiftUI
import UIKit

protocol KeyboardViewModelDelegate: AnyObject {
    func replaceComposition(previous: String, current: String)
    func insertCommittedText(_ text: String)
    func replaceSelectedText(with text: String)
    func deleteBackward()
    func deleteForward()
    func adjustTextPosition(byCharacterOffset offset: Int)
    func selectedTextInDocument() -> String?
    func surroundingTextContext() -> (before: String, after: String)
}

final class KeyboardViewModel: ObservableObject {
    enum Language {
        case korean
        case english
    }

    enum Mode: Equatable {
        case korean
        case english
        case koreanPunctuation
        case englishPunctuation
        case koreanNumber
        case englishNumber
        case koreanArrow
        case englishArrow
        case koreanPhone
        case englishPhone
        case emoji

        var language: Language {
            switch self {
            case .english, .englishPunctuation, .englishNumber, .englishArrow, .englishPhone:
                return .english
            case .korean, .koreanPunctuation, .koreanNumber, .koreanArrow, .koreanPhone, .emoji:
                return .korean
            }
        }

        var isEnglish: Bool {
            language == .english
        }

        var isNumber: Bool {
            self == .koreanNumber || self == .englishNumber
        }

        var isPhone: Bool {
            self == .koreanPhone || self == .englishPhone
        }
    }

    enum ShiftState {
        case off
        case enabled
        case locked
    }

    enum EditingAction {
        case copyAll
        case copy
        case moveUp
        case cut
        case cutAll
        case moveHome
        case selectAll
        case moveLeft
        case toggleSelection
        case moveRight
        case moveEnd
        case deleteForward
        case moveDown
        case paste
        case backspace
        case enter
        case language
        case hanjaNumberPunctuation
        case arrowMode
        case space
    }

    private enum TraitForcedMode {
        case number
        case phone
    }

    @Published private(set) var mode: Mode = .korean
    @Published private(set) var shiftState: ShiftState = .off
    @Published private(set) var needsGlobeKey = true
    @Published private(set) var returnKeyLabel = "return"
    @Published private(set) var punctuationPage = 0
    @Published private(set) var phonePage = 0
    @Published private(set) var emojiCategory = 0
    @Published private(set) var selectionModeEnabled = false

    weak var delegate: KeyboardViewModelDelegate?

    private let assembler = HangulAssembler()
    private var displayedComposition = ""
    private var previousEmojiMode: Mode = .korean
    private var forcedMode: TraitForcedMode?

    func syncTraits(
        keyboardType: UIKeyboardType,
        returnKeyType: UIReturnKeyType,
        needsInputModeSwitchKey: Bool,
        documentContextBeforeInput: String?
    ) {
        needsGlobeKey = needsInputModeSwitchKey
        returnKeyLabel = Self.returnKeyLabel(for: returnKeyType)
        reconcileComposition(documentContextBeforeInput)

        switch keyboardType {
        case .numberPad, .decimalPad, .asciiCapableNumberPad:
            forcedMode = .number
            mode = numberMode(for: mode.language)
        case .phonePad, .namePhonePad:
            forcedMode = .phone
            mode = phoneMode(for: mode.language)
        default:
            if let forcedMode {
                switch forcedMode {
                case .number where mode.isNumber:
                    mode = baseMode(for: mode.language)
                case .phone where mode.isPhone:
                    mode = baseMode(for: mode.language)
                default:
                    break
                }
            }
            forcedMode = nil
        }

        if mode.isEnglish, shiftState != .locked {
            shiftState = shouldAutoCapitalize(documentContextBeforeInput) ? .enabled : .off
        }
    }

    func handleKoreanConsonant(_ consonant: String, gestureTokens: [String]) {
        let previous = displayedComposition
        displayedComposition = append(jamoSequence: [consonant] + resolvedGesture(gestureTokens))
        delegate?.replaceComposition(previous: previous, current: displayedComposition)
    }

    func handleStandaloneVowel(_ vowel: String) {
        let previous = displayedComposition
        displayedComposition = append(jamoSequence: [vowel])
        delegate?.replaceComposition(previous: previous, current: displayedComposition)
    }

    func handleText(_ text: String) {
        commitComposition()
        delegate?.insertCommittedText(shiftOutput(for: text))
        if mode.isEnglish, shiftState == .enabled {
            shiftState = .off
        }
    }

    func handleEmoji(_ emoji: String) {
        commitComposition()
        delegate?.insertCommittedText(emoji)
    }

    func handleBackspace() {
        guard !displayedComposition.isEmpty else {
            delegate?.deleteBackward()
            return
        }

        let previous = displayedComposition
        if let unresolved = assembler.unresolved {
            displayedComposition = displayedComposition.droppingLastCharacters(unresolved.count)
            assembler.removeLastJamo()
            if let newUnresolved = assembler.unresolved {
                displayedComposition += newUnresolved
            }
        } else {
            displayedComposition = displayedComposition.droppingLastCharacters(1)
        }
        delegate?.replaceComposition(previous: previous, current: displayedComposition)
    }

    func toggleShift() {
        guard mode.isEnglish else {
            return
        }
        shiftState = switch shiftState {
        case .off: .enabled
        case .enabled: .locked
        case .locked: .off
        }
    }

    func toggleLanguageMode() {
        commitComposition()
        selectionModeEnabled = false
        switch mode {
        case .korean:
            mode = .english
        case .english:
            mode = .korean
        case .englishPunctuation, .englishNumber, .englishArrow, .englishPhone:
            mode = .english
        case .koreanPunctuation, .koreanNumber, .koreanArrow, .koreanPhone, .emoji:
            mode = .korean
        }
        if !mode.isEnglish {
            shiftState = .off
        }
    }

    func toggleHanjaNumberPunctuationMode() {
        commitComposition()
        selectionModeEnabled = false
        mode = switch mode {
        case .korean, .koreanNumber, .koreanArrow, .koreanPhone, .emoji:
            .koreanPunctuation
        case .english, .englishNumber, .englishArrow, .englishPhone:
            .englishPunctuation
        case .koreanPunctuation:
            .koreanNumber
        case .englishPunctuation:
            .englishNumber
        }
    }

    func toggleArrowMode() {
        commitComposition()
        selectionModeEnabled = false
        mode = arrowMode(for: mode.language)
    }

    func toggleEmojiMode() {
        commitComposition()
        selectionModeEnabled = false
        if mode == .emoji {
            mode = previousEmojiMode
        } else {
            previousEmojiMode = mode
            mode = .emoji
        }
    }

    func advancePunctuationPage() {
        punctuationPage = (punctuationPage + 1) % 5
    }

    func advancePhonePage() {
        phonePage = (phonePage + 1) % 2
    }

    func setEmojiCategory(_ index: Int) {
        emojiCategory = index
    }

    func isSupported(_ action: EditingAction) -> Bool {
        switch action {
        case .moveUp, .moveDown, .selectAll, .toggleSelection:
            return false
        default:
            return true
        }
    }

    func handleEditingAction(_ action: EditingAction) {
        switch action {
        case .copyAll:
            copyAllText()
        case .copy:
            guard let selection = selectedText(), !selection.isEmpty else {
                return
            }
            UIPasteboard.general.string = selection
        case .moveUp, .moveDown:
            return
        case .cut:
            guard let selection = selectedText(), !selection.isEmpty else {
                return
            }
            UIPasteboard.general.string = selection
            commitComposition()
            delegate?.replaceSelectedText(with: "")
        case .cutAll:
            cutAllText()
        case .moveHome:
            commitComposition()
            let before = delegate?.surroundingTextContext().before ?? ""
            if !before.isEmpty {
                delegate?.adjustTextPosition(byCharacterOffset: -before.count)
            }
        case .selectAll, .toggleSelection:
            return
        case .moveLeft:
            commitComposition()
            delegate?.adjustTextPosition(byCharacterOffset: -1)
        case .moveRight:
            commitComposition()
            delegate?.adjustTextPosition(byCharacterOffset: 1)
        case .moveEnd:
            commitComposition()
            let after = delegate?.surroundingTextContext().after ?? ""
            if !after.isEmpty {
                delegate?.adjustTextPosition(byCharacterOffset: after.count)
            }
        case .deleteForward:
            commitComposition()
            if let selection = selectedText(), !selection.isEmpty {
                delegate?.replaceSelectedText(with: "")
            } else {
                delegate?.deleteForward()
            }
        case .paste:
            commitComposition()
            guard let pasted = UIPasteboard.general.string, !pasted.isEmpty else {
                return
            }
            delegate?.replaceSelectedText(with: pasted)
        case .backspace:
            handleBackspace()
        case .enter:
            handleReturn()
        case .language:
            toggleLanguageMode()
        case .hanjaNumberPunctuation:
            toggleHanjaNumberPunctuationMode()
        case .arrowMode:
            toggleArrowMode()
        case .space:
            handleSpace()
        }
    }

    private func handleSpace() {
        commitComposition()
        delegate?.insertCommittedText(" ")
    }

    private func handleReturn() {
        commitComposition()
        delegate?.insertCommittedText("\n")
    }

    func beginCursorScrub() {
        commitComposition()
    }

    func moveCursorHorizontally(by offset: Int) {
        guard offset != 0 else {
            return
        }
        commitComposition()
        delegate?.adjustTextPosition(byCharacterOffset: offset)
    }

    private func append(jamoSequence: [String]) -> String {
        var composition = displayedComposition
        for jamo in jamoSequence {
            if let unresolved = assembler.unresolved {
                composition = composition.droppingLastCharacters(unresolved.count)
            }
            if let resolved = assembler.appendJamo(jamo) {
                composition += resolved
            }
            if let unresolved = assembler.unresolved {
                composition += unresolved
            }
        }
        return composition
    }

    private func resolvedGesture(_ tokens: [String]) -> [String] {
        let processor = MoeumGestureProcessor()
        tokens.forEach { processor.appendMoeum($0) }
        guard let vowel = processor.resolveMoeumList() else {
            return []
        }
        return [vowel]
    }

    private func selectedText() -> String? {
        delegate?.selectedTextInDocument()
    }

    private func allContextText() -> String {
        let surrounding = delegate?.surroundingTextContext() ?? (before: "", after: "")
        let selection = selectedText() ?? ""
        return surrounding.before + selection + surrounding.after
    }

    private func copyAllText() {
        let text = allContextText()
        guard !text.isEmpty else {
            return
        }
        UIPasteboard.general.string = text
    }

    private func cutAllText() {
        let surrounding = delegate?.surroundingTextContext() ?? (before: "", after: "")
        let selection = selectedText() ?? ""
        let text = surrounding.before + selection + surrounding.after
        guard !text.isEmpty else {
            return
        }

        UIPasteboard.general.string = text
        commitComposition()
        if !surrounding.before.isEmpty {
            delegate?.adjustTextPosition(byCharacterOffset: -surrounding.before.count)
        }
        for _ in 0..<text.count {
            delegate?.deleteForward()
        }
    }

    private func commitComposition() {
        assembler.clear()
        displayedComposition = ""
    }

    private func reconcileComposition(_ context: String?) {
        guard !displayedComposition.isEmpty else {
            return
        }
        guard let context, context.hasSuffix(displayedComposition) else {
            commitComposition()
            return
        }
    }

    private func shiftOutput(for text: String) -> String {
        guard mode.isEnglish else {
            return text
        }
        switch shiftState {
        case .off:
            return text.lowercased()
        case .enabled, .locked:
            return text.uppercased()
        }
    }

    private func shouldAutoCapitalize(_ context: String?) -> Bool {
        guard let context, !context.isEmpty else {
            return true
        }
        let trimmed = context.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last else {
            return true
        }
        return [".", "!", "?", "\n"].contains(last)
    }

    private func baseMode(for language: Language) -> Mode {
        language == .english ? .english : .korean
    }

    private func numberMode(for language: Language) -> Mode {
        language == .english ? .englishNumber : .koreanNumber
    }

    private func phoneMode(for language: Language) -> Mode {
        language == .english ? .englishPhone : .koreanPhone
    }

    private func arrowMode(for language: Language) -> Mode {
        language == .english ? .englishArrow : .koreanArrow
    }

    private static func returnKeyLabel(for type: UIReturnKeyType) -> String {
        switch type {
        case .go: "go"
        case .join: "join"
        case .next: "next"
        case .route: "route"
        case .search: "search"
        case .send: "send"
        case .done: "done"
        case .emergencyCall: "call"
        case .continue: "continue"
        default: "return"
        }
    }
}
