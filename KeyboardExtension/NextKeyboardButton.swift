import SwiftUI
import UIKit

struct NextKeyboardButton: UIViewRepresentable {
    let controller: UIInputViewController
    let backgroundColor: UIColor
    let foregroundColor: UIColor
    let borderColor: UIColor

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = borderColor.cgColor
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = backgroundColor
        configuration.baseForegroundColor = foregroundColor
        configuration.image = UIImage(systemName: "globe")
        configuration.cornerStyle = .medium
        button.configuration = configuration
        button.addTarget(
            controller,
            action: #selector(UIInputViewController.handleInputModeList(from:with:)),
            for: .allTouchEvents
        )
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.layer.borderColor = borderColor.cgColor
        uiView.configuration?.baseBackgroundColor = backgroundColor
        uiView.configuration?.baseForegroundColor = foregroundColor
    }
}
