import SwiftUI
import UIKit

private struct KeySpec {
    enum Kind {
        case tap(() -> Void)
        case spaceCursor(tap: () -> Void, beginScrub: () -> Void, moveCursor: (Int) -> Void)
        case repeatAction(() -> Void)
        case koreanGesture(( [String]) -> Void)
        case crossSwipe((CrossSwipeOutput) -> Void)
        case globe
    }

    let label: String
    let widthUnits: CGFloat
    var secondary = false
    var enabled = true
    let kind: Kind
}

private enum CrossSwipeOutput {
    case tap
    case up
    case right
    case down
    case left
}

private enum LandscapeKeyboardSide: String {
    case leading
    case trailing

    var keyboardAlignment: Alignment {
        self == .leading ? .topLeading : .topTrailing
    }

    var handleAlignment: Alignment {
        self == .leading ? .trailing : .leading
    }

    var handleSymbolName: String {
        self == .leading ? "chevron.right" : "chevron.left"
    }

    var accessibilityLabel: String {
        self == .leading ? "Move keyboard right" : "Move keyboard left"
    }
}

struct KeyboardLayoutMetrics {
    let rowSpacing: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let fixedKeyboardWidth: CGFloat?
    let keyHeight: CGFloat
    let emojiFontSize: CGFloat
    let emojiItemHeight: CGFloat
    let emojiCategoryFontSize: CGFloat
    let emojiGridMaxHeight: CGFloat
    let emojiCategoryHeight: CGFloat
    let emojiBottomRowHeight: CGFloat

    static let regular = KeyboardLayoutMetrics(
        rowSpacing: 8,
        horizontalPadding: 10,
        topPadding: 4,
        fixedKeyboardWidth: nil,
        keyHeight: 48,
        emojiFontSize: 28,
        emojiItemHeight: 42,
        emojiCategoryFontSize: 24,
        emojiGridMaxHeight: 192,
        emojiCategoryHeight: 42,
        emojiBottomRowHeight: 48
    )

    static let compact = KeyboardLayoutMetrics(
        rowSpacing: 5,
        horizontalPadding: 6,
        topPadding: 2.5,
        fixedKeyboardWidth: 372,
        keyHeight: 36,
        emojiFontSize: 24,
        emojiItemHeight: 30,
        emojiCategoryFontSize: 20,
        emojiGridMaxHeight: 135,
        emojiCategoryHeight: 32,
        emojiBottomRowHeight: 36
    )

    func preferredHeight(for mode: KeyboardViewModel.Mode) -> CGFloat {
        switch mode {
        case .koreanPunctuation, .englishPunctuation,
             .koreanNumber, .englishNumber,
             .koreanArrow, .englishArrow,
             .koreanPhone, .englishPhone:
            keyHeight * 4 + rowSpacing * 3 + topPadding
        case .emoji:
            emojiCategoryHeight + emojiGridMaxHeight + emojiBottomRowHeight + rowSpacing * 2 + topPadding
        default:
            keyHeight * 5 + rowSpacing * 4 + topPadding
        }
    }
}

private struct KeyboardTheme {
    let backgroundTop: Color
    let backgroundBottom: Color
    let panelFill: Color
    let primaryKey: Color
    let primaryPressed: Color
    let secondaryKey: Color
    let secondaryPressed: Color
    let disabledKey: Color
    let border: Color
    let primaryText: Color
    let secondaryText: Color
    let disabledText: Color

    static func make(for colorScheme: ColorScheme) -> KeyboardTheme {
        switch colorScheme {
        case .dark:
            return KeyboardTheme(
                backgroundTop: Color(red: 0.12, green: 0.13, blue: 0.16),
                backgroundBottom: Color(red: 0.09, green: 0.10, blue: 0.13),
                panelFill: Color.white.opacity(0.12),
                primaryKey: Color(red: 0.30, green: 0.31, blue: 0.35),
                primaryPressed: Color(red: 0.38, green: 0.39, blue: 0.44),
                secondaryKey: Color(red: 0.30, green: 0.31, blue: 0.35),
                secondaryPressed: Color(red: 0.38, green: 0.39, blue: 0.44),
                disabledKey: Color(red: 0.18, green: 0.19, blue: 0.22),
                border: Color.white.opacity(0.10),
                primaryText: .white,
                secondaryText: .white,
                disabledText: Color.white.opacity(0.35)
            )
        default:
            return KeyboardTheme(
                backgroundTop: Color(red: 0.79, green: 0.81, blue: 0.85),
                backgroundBottom: Color(red: 0.73, green: 0.75, blue: 0.80),
                panelFill: Color.white.opacity(0.28),
                primaryKey: Color(red: 0.99, green: 0.99, blue: 1.0),
                primaryPressed: Color(red: 0.88, green: 0.89, blue: 0.92),
                secondaryKey: Color(red: 0.99, green: 0.99, blue: 1.0),
                secondaryPressed: Color(red: 0.88, green: 0.89, blue: 0.92),
                disabledKey: Color(red: 0.82, green: 0.84, blue: 0.88),
                border: Color.black.opacity(0.10),
                primaryText: Color.black.opacity(0.92),
                secondaryText: Color.black.opacity(0.92),
                disabledText: Color.black.opacity(0.35)
            )
        }
    }
}

private enum KeyLabelPresentation {
    case text(String)
    case symbol(name: String, pointSize: CGFloat = 18, weight: Font.Weight = .semibold)

    static func make(for label: String) -> KeyLabelPresentation {
        switch label {
        case "emoji":
            .symbol(name: "face.smiling", pointSize: 21)
        case "delete", "backspace":
            .symbol(name: "delete.left", pointSize: 20)
        case "search":
            .symbol(name: "magnifyingglass", pointSize: 19)
        case "return":
            .symbol(name: "arrow.turn.down.left", pointSize: 19)
        case "go":
            .symbol(name: "arrow.up.forward", pointSize: 19)
        case "next":
            .symbol(name: "arrow.right", pointSize: 19)
        case "route":
            .symbol(name: "arrow.triangle.turn.up.right.diamond", pointSize: 18)
        case "send":
            .symbol(name: "paperplane.fill", pointSize: 18)
        case "done":
            .symbol(name: "checkmark", pointSize: 18)
        case "call":
            .symbol(name: "phone.fill", pointSize: 18)
        case "continue":
            .symbol(name: "arrow.right.circle.fill", pointSize: 18)
        case "join":
            .symbol(name: "link", pointSize: 18)
        case "close":
            .symbol(name: "xmark", pointSize: 18)
        case "shift":
            .symbol(name: "shift", pointSize: 19)
        case "shift*":
            .symbol(name: "shift.fill", pointSize: 19)
        case "caps":
            .symbol(name: "capslock.fill", pointSize: 19)
        default:
            .text(label)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .text(let text):
            return text
        case .symbol:
            return fallbackText
        }
    }

    var fallbackText: String {
        switch self {
        case .text(let text):
            return text
        case .symbol(let name, _, _):
            switch name {
            case "face.smiling": return "emoji"
            case "delete.left": return "delete"
            case "magnifyingglass": return "search"
            case "arrow.turn.down.left": return "return"
            case "arrow.up.forward": return "go"
            case "arrow.right": return "next"
            case "arrow.triangle.turn.up.right.diamond": return "route"
            case "paperplane.fill": return "send"
            case "checkmark": return "done"
            case "phone.fill": return "call"
            case "arrow.right.circle.fill": return "continue"
            case "link": return "join"
            case "xmark": return "close"
            case "shift": return "shift"
            case "shift.fill": return "shift"
            case "capslock.fill": return "caps"
            default: return name
            }
        }
    }
}

struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    let controller: UIInputViewController
    @AppStorage("landscapeKeyboardSide") private var landscapeKeyboardSideRaw = LandscapeKeyboardSide.trailing.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private static let punctuationPages = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
         "-", "@", "*", "^", ":", ";", "(", ")", "~",
         "/", "'", "\"", ".", ",", "?", "!"],
        ["#", "&", "%", "+", "=", "_", "\\", "|", "<", ">",
         "{", "}", "[", "]", "$", "￡", "¥", "€", "₩",
         "¢", "`", "˚", "•", "®", "©", "¿"],
        ["♥", "♡", "◎", "♩", "♬", "♨", "♀", "♂", "☞", "☜",
         "≠", "※", "≒", "♠", "♤", "★", "☆", "♣", "♧",
         "◐", "◆", "◇", "■", "□", "×", "÷"],
        ["Ψ", "Ω", "α", "β", "γ", "δ", "ε", "ζ", "η", "θ",
         "∀", "∂", "∃", "∇", "∈", "∋", "∏", "∑", "∝",
         "∞", "∧", "∨", "∩", "∪", "∫", "∬"],
        ["←", "↑", "→", "↓", "↔", "↕", "↖", "↗", "↘", "↙",
         "∮", "∴", "∵", "≡", "≤", "≥", "≪", "≫", "⌒",
         "⊂", "⊃", "⊆", "⊇", "℃", "℉", "™"],
    ]

    private static let phonePages = [
        [("1", "1"), ("2", "2"), ("3", "3"), ("4", "4"), ("5", "5"),
         ("6", "6"), ("7", "7"), ("8", "8"), ("9", "9"), ("0", "0")],
        [("(", "("), ("/", "/"), (")", ")"), ("N", "N"), ("Pause", ","),
         (",", ","), ("*", "*"), ("Wait", ";"), ("#", "#"), ("+", "+")],
    ]

    private static let emojiCategories: [(label: String, items: [String])] = [
        ("🙂", ["😀", "😃", "😄", "😁", "😂", "🤣", "😊", "😍", "😘", "😎", "🤔", "😭",
               "😡", "🥳", "😴", "🤯", "🥹", "🙌", "👏", "👍", "👎", "🙏", "🫶", "🤝"]),
        ("🐻", ["🐶", "🐱", "🐭", "🐰", "🦊", "🐻", "🐼", "🐯", "🦁", "🐮", "🐷", "🐸",
               "🐵", "🐔", "🐧", "🐦", "🐥", "🦋", "🐢", "🐙", "🌷", "🌳", "🌞", "🌈"]),
        ("🍎", ["🍎", "🍌", "🍇", "🍓", "🍑", "🥝", "🍔", "🍕", "🌭", "🍜", "🍣", "🍙",
               "☕", "🍵", "🍺", "🍷", "🍰", "🍪", "🍿", "🍫", "🧁", "🍩", "🥐", "🍞"]),
        ("⚽", ["⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🎳", "🎮", "🎲", "🎯", "🎸", "🎹",
               "🎤", "🎧", "🎬", "🚗", "🚕", "🚌", "✈️", "🚀", "🏠", "💡", "📱", "💻"]),
        ("❤️", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "💕", "💖",
               "💗", "💘", "💝", "⭐", "✨", "🔥", "💧", "❄️", "☔", "☃️", "🎁", "✅"]),
    ]

    private var theme: KeyboardTheme {
        .make(for: colorScheme)
    }

    private var metrics: KeyboardLayoutMetrics {
        verticalSizeClass == .compact ? .compact : .regular
    }

    private var rowSpacing: CGFloat {
        metrics.rowSpacing
    }

    private var horizontalPadding: CGFloat {
        metrics.horizontalPadding
    }

    private var topPadding: CGFloat {
        metrics.topPadding
    }

    private var landscapeKeyboardSide: LandscapeKeyboardSide {
        get { LandscapeKeyboardSide(rawValue: landscapeKeyboardSideRaw) ?? .trailing }
        nonmutating set { landscapeKeyboardSideRaw = newValue.rawValue }
    }

    private var keyboardAlignment: Alignment {
        verticalSizeClass == .compact ? landscapeKeyboardSide.keyboardAlignment : .topTrailing
    }

    var body: some View {
        GeometryReader { proxy in
            let keyboardWidth = resolvedKeyboardWidth(for: proxy.size.width)
            let handleWidth = max(0, proxy.size.width - keyboardWidth)

            ZStack {
                keyboardBody
                    .padding(.top, topPadding)
                    .padding(.horizontal, horizontalPadding)
                    .frame(width: keyboardWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: keyboardAlignment)

                if shouldShowLandscapeHandle(handleWidth: handleWidth) {
                    landscapeToggleHandle(width: handleWidth, height: proxy.size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: landscapeKeyboardSide.handleAlignment)
                }
            }
        }
    }

    @ViewBuilder
    private var keyboardBody: some View {
        switch viewModel.mode {
        case .korean:
            renderRows(koreanRows)
        case .english:
            renderRows(englishRows)
        case .koreanPunctuation, .englishPunctuation:
            renderRows(punctuationRows)
        case .koreanNumber, .englishNumber:
            renderRows(numberRows)
        case .koreanArrow, .englishArrow:
            renderRows(arrowRows)
        case .koreanPhone, .englishPhone:
            renderRows(phoneRows)
        case .emoji:
            emojiKeyboard
        }
    }

    private var koreanRows: [[KeySpec]] {
        [
            [
                tapKey("~", secondary: true) { viewModel.handleText("~") },
                gestureKey("ㅃ"), gestureKey("ㅉ"), gestureKey("ㄸ"), gestureKey("ㄲ"), gestureKey("ㅆ"),
                tapKey("emoji", secondary: true) { viewModel.toggleEmojiMode() },
            ],
            [
                tapKey("^", secondary: true) { viewModel.handleText("^") },
                gestureKey("ㅂ"), gestureKey("ㅈ"), gestureKey("ㄷ"), gestureKey("ㄱ"), gestureKey("ㅅ"),
                repeatKey("delete", secondary: true) { viewModel.handleBackspace() },
            ],
            [
                tapKey(";", secondary: true) { viewModel.handleText(";") },
                gestureKey("ㅁ"), gestureKey("ㄴ"), gestureKey("ㅇ"), gestureKey("ㄹ"), gestureKey("ㅎ"),
                tapKey("ㅣ", secondary: true) { viewModel.handleStandaloneVowel("ㅣ") },
            ],
            [
                tapKey("*", secondary: true) { viewModel.handleText("*") },
                gestureKey("ㅋ"), gestureKey("ㅌ"), gestureKey("ㅊ"), gestureKey("ㅍ"),
                tapKey("ㅡ", secondary: true) { viewModel.handleStandaloneVowel("ㅡ") },
                tapKey("ㆍ", secondary: true) { viewModel.handleStandaloneVowel("ㆍ") },
            ],
            bottomControlRow(
                centerLeftLabel: "한/영",
                centerLeftAction: { viewModel.handleEditingAction(.language) },
                centerMiddleLabel: "한자/숫자",
                centerMiddleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
                rightAccessory: crossPunctuationKey(),
                rightLabel: viewModel.returnKeyLabel,
                rightAction: { viewModel.handleEditingAction(.enter) }
            ),
        ]
    }

    private var englishRows: [[KeySpec]] {
        let shifted = viewModel.shiftState != .off
        let numberRow = "1234567890".map { character in
            tapKey(String(character), secondary: true) { viewModel.handleText(String(character)) }
        }
        return [
            numberRow,
            letters("qwertyuiop", shifted: shifted),
            letters("asdfghjkl", shifted: shifted),
            [tapKey(shiftLabel, secondary: true) { viewModel.toggleShift() }.withWidth(1.4)]
                + letters("zxcvbnm", shifted: shifted)
                + [repeatKey("delete", secondary: true) { viewModel.handleBackspace() }.withWidth(1.4)],
            bottomControlRow(
                centerLeftLabel: "한/영",
                centerLeftAction: { viewModel.handleEditingAction(.language) },
                centerMiddleLabel: "한자/숫자",
                centerMiddleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
                rightAccessory: crossPunctuationKey(),
                rightLabel: viewModel.returnKeyLabel,
                rightAction: { viewModel.handleEditingAction(.enter) }
            ),
        ]
    }

    private var punctuationRows: [[KeySpec]] {
        let page = Self.punctuationPages[viewModel.punctuationPage]
        let nextPageKey = tapKey(
            "\(viewModel.punctuationPage + 1)/\(Self.punctuationPages.count)",
            secondary: true
        ) {
            viewModel.advancePunctuationPage()
        }.withWidth(1.5)
        let trailingKeys = Array(page[19..<26]).map { symbol in
            tapKey(symbol) { viewModel.handleText(symbol) }
        }
        let leadingKeys = Array(page[0..<10]).map { symbol in
            tapKey(symbol) { viewModel.handleText(symbol) }
        }
        let middleKeys = Array(page[10..<19]).map { symbol in
            tapKey(symbol) { viewModel.handleText(symbol) }
        }
        return [
            leadingKeys,
            middleKeys,
            [nextPageKey]
                + trailingKeys
                + [repeatKey("delete", secondary: true) { viewModel.handleBackspace() }],
            bottomControlRow(
                centerLeftLabel: "한/영",
                centerLeftAction: { viewModel.handleEditingAction(.language) },
                centerMiddleLabel: "한자/숫자",
                centerMiddleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
                rightAccessory: tapKey("arrow", secondary: true) { viewModel.handleEditingAction(.arrowMode) },
                rightLabel: viewModel.returnKeyLabel,
                rightAction: { viewModel.handleEditingAction(.enter) }
            ),
        ]
    }

    private var numberRows: [[KeySpec]] {
        [
            [
                tapKey("+") { viewModel.handleText("+") },
                tapKey("1") { viewModel.handleText("1") },
                tapKey("2") { viewModel.handleText("2") },
                tapKey("3") { viewModel.handleText("3") },
                tapKey("-") { viewModel.handleText("-") },
            ],
            [
                tapKey("*") { viewModel.handleText("*") },
                tapKey("4") { viewModel.handleText("4") },
                tapKey("5") { viewModel.handleText("5") },
                tapKey("6") { viewModel.handleText("6") },
                tapKey(".") { viewModel.handleText(".") },
            ],
            [
                tapKey("/") { viewModel.handleText("/") },
                tapKey("7") { viewModel.handleText("7") },
                tapKey("8") { viewModel.handleText("8") },
                tapKey("9") { viewModel.handleText("9") },
                repeatKey("delete", secondary: true) { viewModel.handleBackspace() },
            ],
            bottomControlRow(
                centerLeftLabel: "한/영",
                centerLeftAction: { viewModel.handleEditingAction(.language) },
                centerMiddleLabel: "한자/숫자",
                centerMiddleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
                extraMiddle: tapKey("0") { viewModel.handleText("0") },
                rightLabel: viewModel.returnKeyLabel,
                rightAction: { viewModel.handleEditingAction(.enter) }
            ),
        ]
    }

    private var phoneRows: [[KeySpec]] {
        let page = Self.phonePages[viewModel.phonePage]
        return [
            [
                tapKey(page[0].0) { viewModel.handleText(page[0].1) },
                tapKey(page[1].0) { viewModel.handleText(page[1].1) },
                tapKey(page[2].0) { viewModel.handleText(page[2].1) },
                repeatKey("delete", secondary: true) { viewModel.handleBackspace() },
            ],
            [
                tapKey(page[3].0) { viewModel.handleText(page[3].1) },
                tapKey(page[4].0) { viewModel.handleText(page[4].1) },
                tapKey(page[5].0) { viewModel.handleText(page[5].1) },
                tapKey("-") { viewModel.handleText("-") },
            ],
            [
                tapKey(page[6].0) { viewModel.handleText(page[6].1) },
                tapKey(page[7].0) { viewModel.handleText(page[7].1) },
                tapKey(page[8].0) { viewModel.handleText(page[8].1) },
                tapKey(".") { viewModel.handleText(".") },
            ],
            [
                tapKey(viewModel.phonePage == 0 ? "punct" : "123", secondary: true) { viewModel.advancePhonePage() },
                tapKey(page[9].0) { viewModel.handleText(page[9].1) },
                tapKey("space") { viewModel.handleEditingAction(.space) },
                tapKey(viewModel.returnKeyLabel, secondary: true) { viewModel.handleEditingAction(.enter) },
            ].withGlobeIfNeeded(controller: controller, needsGlobeKey: viewModel.needsGlobeKey),
        ]
    }

    private var arrowRows: [[KeySpec]] {
        [
            arrowRow([
                arrowKey("copy all", action: .copyAll),
                arrowKey("copy", action: .copy),
                arrowKey("up", action: .moveUp),
                arrowKey("cut", action: .cut),
                arrowKey("cut all", action: .cutAll),
            ]),
            arrowRow([
                arrowKey("home", action: .moveHome),
                arrowKey("left", action: .moveLeft),
                arrowKey("select", action: .toggleSelection),
                arrowKey("right", action: .moveRight),
                arrowKey("select all", action: .selectAll),
            ]),
            arrowRow([
                arrowKey("end", action: .moveEnd),
                arrowKey("delete", action: .deleteForward),
                arrowKey("down", action: .moveDown),
                arrowKey("paste", action: .paste),
                repeatKey("backspace", secondary: true) { viewModel.handleBackspace() },
            ]),
            bottomControlRow(
                centerLeftLabel: "한/영",
                centerLeftAction: { viewModel.handleEditingAction(.language) },
                centerMiddleLabel: "한자/숫자",
                centerMiddleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
                rightLabel: viewModel.returnKeyLabel,
                rightAction: { viewModel.handleEditingAction(.enter) }
            ),
        ]
    }

    private var emojiKeyboard: some View {
        VStack(spacing: rowSpacing) {
            categoryBar
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: rowSpacing), count: 6), spacing: rowSpacing) {
                ForEach(Self.emojiCategories[viewModel.emojiCategory].items, id: \.self) { emoji in
                    Button {
                        viewModel.handleEmoji(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: metrics.emojiFontSize))
                            .frame(maxWidth: .infinity)
                            .frame(height: metrics.emojiItemHeight)
                    }
                    .buttonStyle(OpenMoaKeyStyle(secondary: false, isEnabled: true, theme: theme))
                }
            }
            .frame(height: metrics.emojiGridMaxHeight, alignment: .top)
            HStack(spacing: rowSpacing) {
                if viewModel.needsGlobeKey {
                    NextKeyboardButton(
                        controller: controller,
                        backgroundColor: UIColor(theme.secondaryKey),
                        foregroundColor: UIColor(theme.secondaryText),
                        borderColor: UIColor(theme.border)
                    )
                        .frame(width: metrics.emojiBottomRowHeight, height: metrics.emojiBottomRowHeight)
                }
                KeyButton(label: "close", secondary: true, theme: theme) {
                    viewModel.toggleEmojiMode()
                }
                RepeatActionButton(label: "delete", secondary: true, isEnabled: true, theme: theme) {
                    viewModel.handleBackspace()
                }
                KeyButton(label: "space", theme: theme) {
                    viewModel.handleEditingAction(.space)
                }
                KeyButton(label: viewModel.returnKeyLabel, secondary: true, theme: theme) {
                    viewModel.handleEditingAction(.enter)
                }
            }
            .frame(height: metrics.emojiBottomRowHeight)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var categoryBar: some View {
        HStack(spacing: rowSpacing) {
            ForEach(Array(Self.emojiCategories.enumerated()), id: \.offset) { index, category in
                Button {
                    viewModel.setEmojiCategory(index)
                } label: {
                    Text(category.label)
                        .font(.system(size: metrics.emojiCategoryFontSize))
                        .frame(maxWidth: .infinity)
                        .frame(height: metrics.emojiCategoryHeight)
                }
                .buttonStyle(
                    OpenMoaKeyStyle(
                        secondary: viewModel.emojiCategory == index,
                        isEnabled: true,
                        theme: theme
                    )
                )
            }
        }
    }

    private func renderRows(_ rows: [[KeySpec]]) -> some View {
        VStack(spacing: rowSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                KeyboardRowView(
                    keys: row,
                    rowSpacing: rowSpacing,
                    rowHeight: metrics.keyHeight,
                    controller: controller,
                    theme: theme
                )
            }
        }
    }

    private func letters(_ string: String, shifted: Bool) -> [KeySpec] {
        string.map { char in
            let text = shifted ? String(char).uppercased() : String(char)
            return tapKey(text) { viewModel.handleText(String(char)) }
        }
    }

    private var shiftLabel: String {
        switch viewModel.shiftState {
        case .off: return "shift"
        case .enabled: return "shift*"
        case .locked: return "caps"
        }
    }

    private func gestureKey(_ consonant: String) -> KeySpec {
        KeySpec(label: consonant, widthUnits: 1, kind: .koreanGesture { gestures in
            viewModel.handleKoreanConsonant(consonant, gestureTokens: gestures)
        })
    }

    private func tapKey(_ label: String, secondary: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> KeySpec {
        KeySpec(label: label, widthUnits: 1, secondary: secondary, enabled: enabled, kind: .tap(action))
    }

    private func repeatKey(_ label: String, secondary: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> KeySpec {
        KeySpec(label: label, widthUnits: 1, secondary: secondary, enabled: enabled, kind: .repeatAction(action))
    }

    private func arrowKey(_ label: String, action: KeyboardViewModel.EditingAction) -> KeySpec {
        tapKey(label, secondary: true, enabled: viewModel.isSupported(action)) {
            viewModel.handleEditingAction(action)
        }
    }

    private func crossPunctuationKey() -> KeySpec {
        KeySpec(label: ".,?!", widthUnits: 1, secondary: true, enabled: true, kind: .crossSwipe { output in
            switch output {
            case .tap, .down:
                viewModel.handleText(".")
            case .up:
                viewModel.handleText(",")
            case .right:
                viewModel.handleText("!")
            case .left:
                viewModel.handleText("?")
            }
        })
    }

    private func arrowRow(_ keys: [KeySpec]) -> [KeySpec] {
        keys
    }

    private func bottomControlRow(
        centerLeftLabel: String,
        centerLeftAction: @escaping () -> Void,
        centerMiddleLabel: String,
        centerMiddleAction: @escaping () -> Void,
        extraMiddle: KeySpec? = nil,
        rightAccessory: KeySpec? = nil,
        rightLabel: String,
        rightAction: @escaping () -> Void
    ) -> [KeySpec] {
        var keys: [KeySpec] = []
        if viewModel.needsGlobeKey {
            keys.append(KeySpec(label: "globe", widthUnits: 1, secondary: true, enabled: true, kind: .globe))
        }
        keys.append(tapKey(centerLeftLabel, secondary: true, action: centerLeftAction).withWidth(1.2))
        keys.append(tapKey(centerMiddleLabel, secondary: true, action: centerMiddleAction).withWidth(1.2))
        if let extraMiddle {
            keys.append(extraMiddle.withWidth(1))
        }
        keys.append(
            KeySpec(
                label: "space",
                widthUnits: 1,
                secondary: false,
                enabled: true,
                kind: .spaceCursor(
                    tap: { viewModel.handleEditingAction(.space) },
                    beginScrub: { viewModel.beginCursorScrub() },
                    moveCursor: { offset in viewModel.moveCursorHorizontally(by: offset) }
                )
            )
                .withWidth(extraMiddle == nil && rightAccessory != nil ? 3 : (extraMiddle != nil || rightAccessory != nil ? 1.6 : 2.6))
        )
        if let rightAccessory {
            keys.append(rightAccessory.withWidth(extraMiddle == nil ? 1 : 1.2))
        }
        keys.append(tapKey(rightLabel, secondary: true, action: rightAction).withWidth(1.4))
        return keys
    }

    private func resolvedKeyboardWidth(for availableWidth: CGFloat) -> CGFloat {
        guard verticalSizeClass == .compact else {
            return availableWidth
        }
        return min(availableWidth, metrics.fixedKeyboardWidth ?? availableWidth)
    }

    private func landscapeToggleHandle(width: CGFloat, height: CGFloat) -> some View {
        Button {
            landscapeKeyboardSide = landscapeKeyboardSide == .trailing ? .leading : .trailing
        } label: {
            ZStack {
                Rectangle()
                    .fill(theme.secondaryKey.opacity(0.001))
                Image(systemName: landscapeKeyboardSide.handleSymbolName)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText.opacity(0.55))
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(landscapeKeyboardSide.accessibilityLabel)
    }

    private func shouldShowLandscapeHandle(handleWidth: CGFloat) -> Bool {
        verticalSizeClass == .compact && handleWidth >= 64
    }
}

private struct KeyboardRowView: View {
    let keys: [KeySpec]
    let rowSpacing: CGFloat
    let rowHeight: CGFloat
    let controller: UIInputViewController
    let theme: KeyboardTheme

    var body: some View {
        GeometryReader { proxy in
            let totalUnits = keys.reduce(CGFloat.zero) { $0 + $1.widthUnits }
            let availableWidth = max(
                0,
                proxy.size.width - rowSpacing * CGFloat(max(keys.count - 1, 0))
            )
            let resolvedTotalUnits = max(totalUnits, 1)

            HStack(spacing: rowSpacing) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                    keyView(for: key)
                        .frame(
                            width: max(0, availableWidth * key.widthUnits / resolvedTotalUnits),
                            height: rowHeight
                        )
                }
            }
        }
        .frame(height: rowHeight)
    }

    @ViewBuilder
    private func keyView(for key: KeySpec) -> some View {
        switch key.kind {
        case .tap(let action):
            KeyButton(label: key.label, secondary: key.secondary, isEnabled: key.enabled, theme: theme, action: action)
        case .spaceCursor(let tap, let beginScrub, let moveCursor):
            SpaceCursorKey(
                label: key.label,
                secondary: key.secondary,
                isEnabled: key.enabled,
                theme: theme,
                tapAction: tap,
                beginScrub: beginScrub,
                moveCursor: moveCursor
            )
        case .repeatAction(let action):
            RepeatActionButton(label: key.label, secondary: key.secondary, isEnabled: key.enabled, theme: theme, action: action)
        case .koreanGesture(let action):
            KoreanGestureKey(label: key.label, isEnabled: key.enabled, theme: theme, action: action)
        case .crossSwipe(let action):
            CrossSwipeKey(label: key.label, isEnabled: key.enabled, theme: theme, action: action)
        case .globe:
            NextKeyboardButton(
                controller: controller,
                backgroundColor: UIColor(theme.secondaryKey),
                foregroundColor: UIColor(theme.secondaryText),
                borderColor: UIColor(theme.border)
            )
        }
    }
}

private struct KeyButton: View {
    let label: String
    var secondary = false
    var isEnabled = true
    let theme: KeyboardTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            keyLabel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(keyForegroundColor)
        }
        .buttonStyle(OpenMoaKeyStyle(secondary: secondary, isEnabled: isEnabled, theme: theme))
        .disabled(!isEnabled)
        .accessibilityLabel(KeyLabelPresentation.make(for: label).accessibilityLabel)
    }

    private var keyForegroundColor: Color {
        guard isEnabled else {
            return theme.disabledText
        }
        return secondary ? theme.secondaryText : theme.primaryText
    }

    @ViewBuilder
    private var keyLabel: some View {
        switch KeyLabelPresentation.make(for: label) {
        case .text(let text):
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
        case .symbol(let name, let pointSize, let weight):
            Image(systemName: name)
                .font(.system(size: pointSize, weight: weight, design: .rounded))
        }
    }
}

private struct KoreanGestureKey: View {
    let label: String
    var isEnabled = true
    let theme: KeyboardTheme
    let action: ([String]) -> Void

    @State private var lastPoint: CGPoint?
    @State private var tokens: [String] = []

    private let threshold: CGFloat = 26

    var body: some View {
        Text(label)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isEnabled ? theme.primaryText : theme.disabledText)
            .modifier(OpenMoaKeyChrome(secondary: false, isEnabled: isEnabled, theme: theme))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else {
                            return
                        }
                        if lastPoint == nil {
                            lastPoint = value.startLocation
                        }
                        guard let point = lastPoint else {
                            return
                        }
                        let dx = value.location.x - point.x
                        let dy = value.location.y - point.y
                        let distance = sqrt(dx * dx + dy * dy)
                        guard distance > threshold else {
                            return
                        }
                        if let token = gestureToken(dx: dx, dy: dy) {
                            tokens.append(token)
                        }
                        lastPoint = value.location
                    }
                    .onEnded { _ in
                        guard isEnabled else {
                            return
                        }
                        action(tokens)
                        lastPoint = nil
                        tokens.removeAll()
                    }
            )
            .opacity(isEnabled ? 1 : 0.45)
    }

    private func gestureToken(dx: CGFloat, dy: CGFloat) -> String? {
        let degree = atan2(dy, dx) * 180 / .pi
        if abs(degree) > 0.001, abs(degree) < 22.5 {
            return "ㅏ"
        }
        if abs(degree) < 67.5 {
            return degree > 0 ? "ㅡR" : "ㅣR"
        }
        if abs(degree) < 112.5 {
            return degree > 0 ? "ㅜ" : "ㅗ"
        }
        if abs(degree) < 157.5 {
            return degree > 0 ? "ㅡL" : "ㅣL"
        }
        if abs(degree) <= 180 {
            return "ㅓ"
        }
        return nil
    }
}

private struct SpaceCursorKey: View {
    let label: String
    var secondary = false
    var isEnabled = true
    let theme: KeyboardTheme
    let tapAction: () -> Void
    let beginScrub: () -> Void
    let moveCursor: (Int) -> Void

    @State private var touchStartTime: Date?
    @State private var isPressed = false
    @State private var isScrubbing = false
    @State private var lastStep = 0
    @State private var repeatTimer: Timer?
    @State private var repeatDirection = 0

    private let longPressThreshold: TimeInterval = 0.35
    private let tapSlop: CGFloat = 10
    private let stepWidth: CGFloat = 9
    private let repeatActivationDistance: CGFloat = 72
    private let repeatInterval: TimeInterval = 0.06

    var body: some View {
        keyLabel
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(keyForegroundColor)
            .modifier(
                OpenMoaKeyChrome(
                    secondary: secondary,
                    isEnabled: isEnabled,
                    pressed: isPressed || isScrubbing,
                    theme: theme
                )
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else {
                            return
                        }
                        if touchStartTime == nil {
                            touchStartTime = Date()
                            isPressed = true
                        }

                        let elapsed = Date().timeIntervalSince(touchStartTime ?? Date())
                        guard elapsed >= longPressThreshold else {
                            return
                        }
                        if !isScrubbing {
                            isScrubbing = true
                            beginScrub()
                        }

                        let step = Int((value.translation.width / stepWidth).rounded(.towardZero))
                        let delta = step - lastStep
                        guard delta != 0 else {
                            updateAutoRepeat(for: value.translation.width)
                            return
                        }
                        moveCursor(delta)
                        lastStep = step
                        updateAutoRepeat(for: value.translation.width)
                    }
                    .onEnded { value in
                        guard isEnabled else {
                            reset()
                            return
                        }

                        let duration = touchStartTime.map { Date().timeIntervalSince($0) } ?? 0
                        let distance = hypot(value.translation.width, value.translation.height)
                        if !isScrubbing && duration < longPressThreshold && distance <= tapSlop {
                            tapAction()
                        }
                        reset()
                    }
            )
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.08), value: isPressed || isScrubbing)
            .accessibilityLabel(KeyLabelPresentation.make(for: label).accessibilityLabel)
            .onDisappear {
                stopAutoRepeat()
            }
    }

    private var keyForegroundColor: Color {
        guard isEnabled else {
            return theme.disabledText
        }
        return secondary ? theme.secondaryText : theme.primaryText
    }

    @ViewBuilder
    private var keyLabel: some View {
        switch KeyLabelPresentation.make(for: label) {
        case .text(let text):
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
        case .symbol(let name, let pointSize, let weight):
            Image(systemName: name)
                .font(.system(size: pointSize, weight: weight, design: .rounded))
        }
    }

    private func reset() {
        stopAutoRepeat()
        touchStartTime = nil
        isPressed = false
        isScrubbing = false
        lastStep = 0
    }

    private func updateAutoRepeat(for translationWidth: CGFloat) {
        guard isScrubbing else {
            stopAutoRepeat()
            return
        }

        let direction: Int
        if translationWidth >= repeatActivationDistance {
            direction = 1
        } else if translationWidth <= -repeatActivationDistance {
            direction = -1
        } else {
            direction = 0
        }

        guard direction != 0 else {
            stopAutoRepeat()
            return
        }
        guard repeatDirection != direction || repeatTimer == nil else {
            return
        }

        stopAutoRepeat()
        repeatDirection = direction
        repeatTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { _ in
            moveCursor(direction)
        }
    }

    private func stopAutoRepeat() {
        repeatTimer?.invalidate()
        repeatTimer = nil
        repeatDirection = 0
    }
}

private struct CrossSwipeKey: View {
    let label: String
    var isEnabled = true
    let theme: KeyboardTheme
    let action: (CrossSwipeOutput) -> Void

    @State private var startPoint: CGPoint?
    private let threshold: CGFloat = 24

    var body: some View {
        Text(label)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isEnabled ? theme.secondaryText : theme.disabledText)
            .modifier(OpenMoaKeyChrome(secondary: true, isEnabled: isEnabled, theme: theme))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if startPoint == nil {
                            startPoint = value.startLocation
                        }
                    }
                    .onEnded { value in
                        guard isEnabled else {
                            return
                        }
                        let output = resolveOutput(start: startPoint ?? value.startLocation, end: value.location)
                        action(output)
                        startPoint = nil
                    }
            )
            .opacity(isEnabled ? 1 : 0.45)
    }

    private func resolveOutput(start: CGPoint, end: CGPoint) -> CrossSwipeOutput {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > threshold else {
            return .tap
        }
        let degree = atan2(dy, dx) * 180 / .pi
        if abs(degree) < 45 {
            return .right
        }
        if abs(degree) < 135 {
            return degree < 0 ? .up : .down
        }
        return .left
    }
}

private struct RepeatActionButton: UIViewRepresentable {
    let label: String
    var secondary = false
    var isEnabled = true
    let theme: KeyboardTheme
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.addTarget(context.coordinator, action: #selector(Coordinator.touchDown), for: .touchDown)
        button.addTarget(context.coordinator, action: #selector(Coordinator.touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        let presentation = KeyLabelPresentation.make(for: label)
        uiView.isEnabled = isEnabled
        uiView.alpha = isEnabled ? 1 : 0.45
        uiView.backgroundColor = backgroundColor(pressed: false)
        uiView.layer.borderColor = UIColor(theme.border).cgColor
        uiView.setTitleColor(UIColor(secondary ? theme.secondaryText : theme.primaryText), for: .normal)
        uiView.tintColor = UIColor(secondary ? theme.secondaryText : theme.primaryText)
        uiView.accessibilityLabel = presentation.accessibilityLabel
        switch presentation {
        case .text(let text):
            uiView.setTitle(text, for: .normal)
            uiView.setImage(nil, for: .normal)
            uiView.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        case .symbol(let name, let pointSize, _):
            uiView.setTitle(nil, for: .normal)
            uiView.setImage(UIImage(systemName: name), for: .normal)
            uiView.setPreferredSymbolConfiguration(
                UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold),
                forImageIn: .normal
            )
        }
        context.coordinator.action = action
        context.coordinator.isEnabled = isEnabled
        context.coordinator.secondary = secondary
        context.coordinator.theme = theme
    }

    private func backgroundColor(pressed: Bool) -> UIColor {
        guard isEnabled else {
            return UIColor(theme.disabledKey)
        }
        if secondary {
            return UIColor(pressed ? theme.secondaryPressed : theme.secondaryKey)
        }
        return UIColor(pressed ? theme.primaryPressed : theme.primaryKey)
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        var isEnabled = true
        var secondary = false
        var theme: KeyboardTheme = .make(for: .light)
        private var repeatTimer: Timer?
        private var delayedStart: DispatchWorkItem?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func touchDown(_ sender: UIButton) {
            guard isEnabled else {
                return
            }
            sender.backgroundColor = UIColor(secondary ? theme.secondaryPressed : theme.primaryPressed)
            action()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else {
                    return
                }
                self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    self.action()
                }
            }
            delayedStart = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }

        @objc func touchUp(_ sender: UIButton) {
            sender.backgroundColor = UIColor(secondary ? theme.secondaryKey : theme.primaryKey)
            delayedStart?.cancel()
            delayedStart = nil
            repeatTimer?.invalidate()
            repeatTimer = nil
        }
    }
}

private struct OpenMoaKeyStyle: ButtonStyle {
    let secondary: Bool
    let isEnabled: Bool
    let theme: KeyboardTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(
                OpenMoaKeyChrome(
                    secondary: secondary,
                    isEnabled: isEnabled,
                    pressed: configuration.isPressed,
                    theme: theme
                )
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1.0)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

private struct OpenMoaKeyChrome: ViewModifier {
    let secondary: Bool
    let isEnabled: Bool
    var pressed = false
    let theme: KeyboardTheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.border, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        guard isEnabled else {
            return theme.disabledKey
        }
        if secondary {
            return pressed ? theme.secondaryPressed : theme.secondaryKey
        }
        return pressed ? theme.primaryPressed : theme.primaryKey
    }

}

private extension KeySpec {
    func withWidth(_ widthUnits: CGFloat) -> KeySpec {
        KeySpec(label: label, widthUnits: widthUnits, secondary: secondary, enabled: enabled, kind: kind)
    }
}

private extension Array where Element == KeySpec {
    func withGlobeIfNeeded(controller: UIInputViewController, needsGlobeKey: Bool) -> [KeySpec] {
        guard needsGlobeKey else {
            return self
        }
        return [KeySpec(label: "globe", widthUnits: 1, secondary: true, enabled: true, kind: .globe)] + self
    }
}
