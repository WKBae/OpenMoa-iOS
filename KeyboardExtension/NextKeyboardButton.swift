import SwiftUI
import UIKit

struct NextKeyboardButton: UIViewRepresentable {
    private static let surfaceViewTag = 7_401

    let controller: UIInputViewController
    let backgroundColor: UIColor
    let foregroundColor: UIColor
    let borderColor: UIColor

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.clipsToBounds = false
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = foregroundColor
        configureBackground(for: button)
        button.addTarget(
            controller,
            action: #selector(UIInputViewController.handleInputModeList(from:with:)),
            for: .allTouchEvents
        )
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.tintColor = foregroundColor
        configureBackground(for: uiView)
    }

    private func configureBackground(for button: UIButton) {
        button.configuration = nil
        button.backgroundColor = .clear
        let surfaceView = ensureSurfaceView(in: button)
        surfaceView.update(
            secondary: true,
            isEnabled: button.isEnabled,
            pressed: false,
            theme: inferredTheme
        )
        if #unavailable(iOSApplicationExtension 26.0) {
            surfaceView.layer.borderColor = borderColor.cgColor
        }
    }

    private var inferredTheme: KeyboardTheme {
        KeyboardTheme(
            primaryKey: Color(backgroundColor),
            primaryPressed: Color(backgroundColor),
            secondaryKey: Color(backgroundColor),
            secondaryPressed: Color(backgroundColor),
            disabledKey: Color(backgroundColor).opacity(0.45),
            border: Color(borderColor),
            primaryText: Color(foregroundColor),
            secondaryText: Color(foregroundColor),
            disabledText: Color(foregroundColor).opacity(0.45)
        )
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
}
