import SwiftUI
import UIKit

private struct KeySpec {
    enum Kind {
        case tap(() -> Void)
        case spaceCursor(tap: () -> Void, beginScrub: () -> Void, moveCursor: (Int) -> Void)
        case repeatAction(() -> Void)
        case koreanGesture(action: ([String]) -> Void, longPressAction: (() -> Void)?)
        case crossSwipe((CrossSwipeOutput) -> Void)
        case globe
    }

    let label: String
    let widthUnits: CGFloat
    var hint: String?
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

    private static let regularBase = KeyboardLayoutMetrics(
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

    private static let compactBase = KeyboardLayoutMetrics(
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

    static func regular(preferences: KeyboardPreferences.LayoutValues) -> KeyboardLayoutMetrics {
        scaled(
            from: regularBase,
            fiveRowHeight: preferences.portraitKeyboardHeight,
            fixedKeyboardWidth: nil
        )
    }

    static func compact(preferences: KeyboardPreferences.LayoutValues) -> KeyboardLayoutMetrics {
        scaled(
            from: compactBase,
            fiveRowHeight: preferences.landscapeKeyboardHeight,
            fixedKeyboardWidth: preferences.landscapeKeyboardWidth
        )
    }

    func preferredHeight(for mode: KeyboardViewModel.Mode) -> CGFloat {
        switch mode {
        case .punctuation,
             .number,
             .phone:
            keyHeight * 4 + rowSpacing * 3 + topPadding
        case .emoji:
            emojiCategoryHeight + emojiGridMaxHeight + emojiBottomRowHeight + rowSpacing * 2 + topPadding
        default:
            keyHeight * 5 + rowSpacing * 4 + topPadding
        }
    }

    private static func scaled(
        from base: KeyboardLayoutMetrics,
        fiveRowHeight: CGFloat,
        fixedKeyboardWidth: CGFloat?
    ) -> KeyboardLayoutMetrics {
        let baseHeight = base.preferredHeight(for: .korean)
        let scale = max(0.75, fiveRowHeight / max(baseHeight, 1))

        return KeyboardLayoutMetrics(
            rowSpacing: base.rowSpacing * scale,
            horizontalPadding: base.horizontalPadding,
            topPadding: base.topPadding * scale,
            fixedKeyboardWidth: fixedKeyboardWidth,
            keyHeight: base.keyHeight * scale,
            emojiFontSize: base.emojiFontSize * scale,
            emojiItemHeight: base.emojiItemHeight * scale,
            emojiCategoryFontSize: base.emojiCategoryFontSize * scale,
            emojiGridMaxHeight: base.emojiGridMaxHeight * scale,
            emojiCategoryHeight: base.emojiCategoryHeight * scale,
            emojiBottomRowHeight: base.emojiBottomRowHeight * scale
        )
    }
}

struct KeyboardTheme {
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
                primaryKey: Color.white.opacity(0.16),
                primaryPressed: Color.white.opacity(0.24),
                secondaryKey: Color.white.opacity(0.12),
                secondaryPressed: Color.white.opacity(0.20),
                disabledKey: Color.white.opacity(0.08),
                border: Color.white.opacity(0.14),
                primaryText: .white,
                secondaryText: .white,
                disabledText: Color.white.opacity(0.35)
            )
        default:
            return KeyboardTheme(
                primaryKey: Color.white.opacity(0.91),
                primaryPressed: Color.white.opacity(0.74),
                secondaryKey: Color.white.opacity(0.86),
                secondaryPressed: Color.white.opacity(0.68),
                disabledKey: Color.white.opacity(0.34),
                border: Color.black.opacity(0.09),
                primaryText: Color.black.opacity(0.92),
                secondaryText: Color.black.opacity(0.92),
                disabledText: Color.black.opacity(0.35)
            )
        }
    }
}

private enum KeyLabelPresentation {
    case text(String)
    case symbol(name: String, pointSize: CGFloat = 18, weight: Font.Weight = .regular)

    static func make(for label: String) -> KeyLabelPresentation {
        switch label {
        case "emoji":
            .symbol(name: "face.smiling", pointSize: 21)
        case "delete", "backspace":
            .symbol(name: "delete.left", pointSize: 18, weight: .regular)
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
        case "space":
            .text("")
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
        let preferences = KeyboardPreferences.layoutValues
        return verticalSizeClass == .compact
            ? .compact(preferences: preferences)
            : .regular(preferences: preferences)
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

    private var spaceLeadingKey: String {
        KeyboardPreferences.spaceLeadingKeyValue
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
        case .punctuation:
            renderRows(punctuationRows)
        case .number:
            renderRows(numberRows)
        case .phone:
            renderRows(phoneRows)
        case .emoji:
            emojiKeyboard
        }
    }

    private var koreanRows: [[KeySpec]] {
        let leadingKeys = KeyboardPreferences.koreanLeadingKeyValues
        return [
            [
                tapKey(leadingKeys.top, secondary: true) { viewModel.handleText(leadingKeys.top) },
                gestureKey("ㅃ"), gestureKey("ㅉ"), gestureKey("ㄸ"), gestureKey("ㄲ"), gestureKey("ㅆ"),
                tapKey("emoji", secondary: true) { viewModel.toggleEmojiMode() },
            ],
            [
                tapKey(leadingKeys.upperMiddle, secondary: true) { viewModel.handleText(leadingKeys.upperMiddle) },
                gestureKey("ㅂ"), gestureKey("ㅈ"), gestureKey("ㄷ"), gestureKey("ㄱ"), gestureKey("ㅅ"),
                repeatKey("delete", secondary: true) { viewModel.handleBackspace() },
            ],
            [
                tapKey(leadingKeys.lowerMiddle, secondary: true) { viewModel.handleText(leadingKeys.lowerMiddle) },
                gestureKey("ㅁ"), gestureKey("ㄴ"), gestureKey("ㅇ"), gestureKey("ㄹ"), gestureKey("ㅎ"),
                tapKey("ㅣ", secondary: true) { viewModel.handleStandaloneVowel("ㅣ") },
            ],
            [
                tapKey(leadingKeys.bottom, secondary: true) { viewModel.handleText(leadingKeys.bottom) },
                gestureKey("ㅋ"), gestureKey("ㅌ"), gestureKey("ㅊ"), gestureKey("ㅍ"),
                tapKey("ㅡ", secondary: true) { viewModel.handleStandaloneVowel("ㅡ") },
                tapKey("ㆍ", secondary: true) { viewModel.handleStandaloneVowel("ㆍ") },
            ],
            bottomControlRow(
                cycleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
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
                cycleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
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
                cycleAction: { viewModel.handleEditingAction(.hanjaNumberPunctuation) },
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

    private func gestureKey(_ consonant: String) -> KeySpec {
        let hint = numberHint(for: consonant)
        return KeySpec(
            label: consonant,
            widthUnits: 1,
            hint: hint,
            kind: .koreanGesture(
                action: { gestures in
                    viewModel.handleKoreanConsonant(consonant, gestureTokens: gestures)
                },
                longPressAction: hint.map { digit in
                    { viewModel.handleText(digit) }
                }
            )
        )
    }

    private func tapKey(_ label: String, secondary: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> KeySpec {
        KeySpec(label: label, widthUnits: 1, secondary: secondary, enabled: enabled, kind: .tap(action))
    }

    private func repeatKey(_ label: String, secondary: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> KeySpec {
        KeySpec(label: label, widthUnits: 1, secondary: secondary, enabled: enabled, kind: .repeatAction(action))
    }

    private func numberHint(for consonant: String) -> String? {
        switch consonant {
        case "ㅂ": return "1"
        case "ㅈ": return "2"
        case "ㄷ": return "3"
        case "ㄱ": return "4"
        case "ㅅ": return "5"
        case "ㅁ": return "6"
        case "ㄴ": return "7"
        case "ㅇ": return "8"
        case "ㄹ": return "9"
        case "ㅎ": return "0"
        default: return nil
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

    private func bottomControlRow(
        cycleAction: @escaping () -> Void,
        extraMiddle: KeySpec? = nil,
        rightAccessory: KeySpec? = nil,
        rightLabel: String,
        rightAction: @escaping () -> Void
    ) -> [KeySpec] {
        var keys: [KeySpec] = []
        if viewModel.needsGlobeKey {
            keys.append(KeySpec(label: "globe", widthUnits: 1, secondary: true, enabled: true, kind: .globe))
        }
        keys.append(tapKey("!#1", secondary: true, action: cycleAction).withWidth(1.2))
        if let extraMiddle {
            keys.append(extraMiddle.withWidth(1))
        }
        keys.append(tapKey(spaceLeadingKey, secondary: true) { viewModel.handleText(spaceLeadingKey) }.withWidth(0.9))
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
                .withWidth(extraMiddle == nil && rightAccessory != nil ? 3.3 : (extraMiddle != nil || rightAccessory != nil ? 2.1 : 3.7))
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
        case .koreanGesture(let action, let longPressAction):
            KoreanGestureKey(
                label: key.label,
                hint: key.hint,
                isEnabled: key.enabled,
                theme: theme,
                action: action,
                longPressAction: longPressAction
            )
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
                .font(.system(size: 17, weight: .regular, design: .rounded))
        case .symbol(let name, let pointSize, let weight):
            Image(systemName: name)
                .font(.system(size: pointSize, weight: weight, design: .rounded))
        }
    }
}

private struct KoreanGestureKey: View {
    let label: String
    let hint: String?
    var isEnabled = true
    let theme: KeyboardTheme
    let action: ([String]) -> Void
    let longPressAction: (() -> Void)?

    @State private var startPoint: CGPoint?
    @State private var lastPoint: CGPoint?
    @State private var latestPoint: CGPoint?
    @State private var tokens: [String] = []
    @State private var longPressTimer: Timer?
    @State private var didTriggerLongPress = false
    @State private var isPressed = false

    private let threshold: CGFloat = 26
    private let tapSlop: CGFloat = 10
    private let longPressThreshold: TimeInterval = 0.35

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(label)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let hint {
                Text(hint)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(isEnabled ? theme.primaryText.opacity(0.45) : theme.disabledText)
                    .padding(.top, 6)
                    .padding(.trailing, 8)
            }
        }
            .foregroundStyle(isEnabled ? theme.primaryText : theme.disabledText)
            .modifier(OpenMoaKeyChrome(secondary: false, isEnabled: isEnabled, pressed: isPressed, theme: theme))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else {
                            return
                        }
                        if startPoint == nil {
                            beginTouch(at: value.startLocation)
                        }
                        latestPoint = value.location
                        guard !didTriggerLongPress else {
                            return
                        }
                        if distanceFromStart() > tapSlop {
                            cancelLongPressTimer()
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
                        cancelLongPressTimer()
                        if let token = gestureToken(dx: dx, dy: dy) {
                            tokens.append(token)
                        }
                        lastPoint = value.location
                    }
                    .onEnded { _ in
                        guard isEnabled else {
                            reset()
                            return
                        }
                        if !didTriggerLongPress {
                            action(tokens)
                        }
                        reset()
                    }
            )
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.08), value: isPressed)
            .accessibilityLabel(KeyLabelPresentation.make(for: label).accessibilityLabel)
            .accessibilityHint(hint.map { "Long press for \($0)" } ?? "")
            .onDisappear {
                reset()
            }
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

    private func beginTouch(at point: CGPoint) {
        startPoint = point
        lastPoint = point
        latestPoint = point
        isPressed = true
        scheduleLongPressIfNeeded()
    }

    private func scheduleLongPressIfNeeded() {
        guard longPressAction != nil else {
            return
        }
        cancelLongPressTimer()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: longPressThreshold, repeats: false) { _ in
            guard !self.didTriggerLongPress, self.tokens.isEmpty, self.distanceFromStart() <= self.tapSlop else {
                return
            }
            self.didTriggerLongPress = true
            self.longPressAction?()
        }
    }

    private func cancelLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private func distanceFromStart() -> CGFloat {
        guard let startPoint, let latestPoint else {
            return .zero
        }
        return hypot(latestPoint.x - startPoint.x, latestPoint.y - startPoint.y)
    }

    private func reset() {
        cancelLongPressTimer()
        startPoint = nil
        lastPoint = nil
        latestPoint = nil
        tokens.removeAll()
        didTriggerLongPress = false
        isPressed = false
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
        crossSwipeLabel
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
            .accessibilityLabel(KeyLabelPresentation.make(for: label).accessibilityLabel)
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

    @ViewBuilder
    private var crossSwipeLabel: some View {
        if label == ".,?!" {
            ZStack {
                Text(",")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(y: -7)

                HStack {
                    Text("?")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Spacer(minLength: 0)
                    Text("!")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)

                Text(".")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .baselineOffset(-2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text(label)
                .font(.system(size: 15, weight: .regular, design: .rounded))
        }
    }
}

final class UIKitKeySurfaceView: UIView {
    private let fallbackView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.cornerRadius = 12
        layer.masksToBounds = true

        fallbackView.translatesAutoresizingMaskIntoConstraints = false
        fallbackView.isUserInteractionEnabled = false
        fallbackView.layer.cornerRadius = 12
        fallbackView.layer.masksToBounds = true
        addSubview(fallbackView)

        NSLayoutConstraint.activate([
            fallbackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fallbackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fallbackView.topAnchor.constraint(equalTo: topAnchor),
            fallbackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(secondary: Bool, isEnabled: Bool, pressed: Bool, theme: KeyboardTheme) {
        alpha = isEnabled ? 1 : 0.45
        fallbackView.isHidden = false
        fallbackView.backgroundColor = fallbackColor(secondary: secondary, pressed: pressed, theme: theme)
        if #available(iOSApplicationExtension 26.0, *) {
            layer.borderWidth = 0
            layer.borderColor = nil
        } else {
            layer.borderWidth = 1
            layer.borderColor = UIColor(theme.border).cgColor
        }
        backgroundColor = .clear
    }

    private func fallbackColor(secondary: Bool, pressed: Bool, theme: KeyboardTheme) -> UIColor {
        if secondary {
            return UIColor(pressed ? theme.secondaryPressed : theme.secondaryKey)
        }
        return UIColor(pressed ? theme.primaryPressed : theme.primaryKey)
    }
}

private struct UIKitKeyChromeBackground: UIViewRepresentable {
    let secondary: Bool
    let isEnabled: Bool
    let pressed: Bool
    let theme: KeyboardTheme

    func makeUIView(context: Context) -> UIKitKeySurfaceView {
        UIKitKeySurfaceView()
    }

    func updateUIView(_ uiView: UIKitKeySurfaceView, context: Context) {
        uiView.update(secondary: secondary, isEnabled: isEnabled, pressed: pressed, theme: theme)
    }
}

private struct RepeatActionButton: UIViewRepresentable {
    private static let surfaceViewTag = 7_402
    private static let titleLabelTag = 7_403
    private static let imageViewTag = 7_404

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
        button.clipsToBounds = false
        button.addTarget(context.coordinator, action: #selector(Coordinator.touchDown), for: .touchDown)
        button.addTarget(context.coordinator, action: #selector(Coordinator.touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        installForegroundViews(in: button)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        let presentation = KeyLabelPresentation.make(for: label)
        uiView.isEnabled = isEnabled
        uiView.alpha = isEnabled ? 1 : 0.45
        applyBackground(to: uiView, pressed: false)
        let foregroundColor = UIColor(secondary ? theme.secondaryText : theme.primaryText)
        uiView.setTitle(nil, for: .normal)
        uiView.setImage(nil, for: .normal)
        uiView.setTitleColor(foregroundColor, for: .normal)
        uiView.tintColor = foregroundColor
        uiView.accessibilityLabel = presentation.accessibilityLabel
        let titleLabel = uiView.viewWithTag(Self.titleLabelTag) as? UILabel
        let imageView = uiView.viewWithTag(Self.imageViewTag) as? UIImageView
        switch presentation {
        case .text(let text):
            titleLabel?.isHidden = false
            titleLabel?.text = text
            titleLabel?.textColor = foregroundColor
            titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            imageView?.isHidden = true
        case .symbol(let name, let pointSize, _):
            titleLabel?.isHidden = true
            imageView?.isHidden = false
            let symbolConfiguration: UIImage.SymbolConfiguration
            if name == "delete.left" {
                symbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular, scale: .medium)
            } else {
                symbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
            }
            imageView?.preferredSymbolConfiguration = symbolConfiguration
            imageView?.image = UIImage(systemName: name, withConfiguration: symbolConfiguration)
            imageView?.tintColor = foregroundColor
        }
        context.coordinator.action = action
        context.coordinator.isEnabled = isEnabled
        context.coordinator.secondary = secondary
        context.coordinator.theme = theme
        context.coordinator.applyBackground = applyBackground
    }

    private func applyBackground(to button: UIButton, pressed: Bool) {
        button.configuration = nil
        button.backgroundColor = .clear
        let surfaceView = ensureSurfaceView(in: button)
        surfaceView.update(secondary: secondary, isEnabled: isEnabled, pressed: pressed, theme: theme)
    }

    private func ensureSurfaceView(in button: UIButton) -> UIKitKeySurfaceView {
        if let existing = button.viewWithTag(Self.surfaceViewTag) as? UIKitKeySurfaceView {
            return existing
        }

        let surfaceView = UIKitKeySurfaceView()
        surfaceView.tag = Self.surfaceViewTag
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        button.insertSubview(surfaceView, at: 0)
        NSLayoutConstraint.activate([
            surfaceView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            surfaceView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            surfaceView.topAnchor.constraint(equalTo: button.topAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
        return surfaceView
    }

    private func installForegroundViews(in button: UIButton) {
        guard button.viewWithTag(Self.titleLabelTag) == nil, button.viewWithTag(Self.imageViewTag) == nil else {
            return
        }

        let titleLabel = UILabel()
        titleLabel.tag = Self.titleLabelTag
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        button.addSubview(titleLabel)

        let imageView = UIImageView()
        imageView.tag = Self.imageViewTag
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        button.addSubview(imageView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: button.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        var isEnabled = true
        var secondary = false
        var theme: KeyboardTheme = .make(for: .light)
        var applyBackground: ((UIButton, Bool) -> Void)?
        private var repeatTimer: Timer?
        private var delayedStart: DispatchWorkItem?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func touchDown(_ sender: UIButton) {
            guard isEnabled else {
                return
            }
            applyBackground?(sender, true)
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
            applyBackground?(sender, false)
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

    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .background(
                UIKitKeyChromeBackground(
                    secondary: secondary,
                    isEnabled: isEnabled,
                    pressed: pressed,
                    theme: theme
                )
            )
    }

}

private extension KeySpec {
    func withWidth(_ widthUnits: CGFloat) -> KeySpec {
        KeySpec(label: label, widthUnits: widthUnits, hint: hint, secondary: secondary, enabled: enabled, kind: kind)
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
