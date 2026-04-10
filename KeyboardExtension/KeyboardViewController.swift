import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum Layout {
        static let regularHeight: CGFloat = 296
        static let compactHeight: CGFloat = 236
    }

    private let viewModel = KeyboardViewModel()
    private var hostingController: UIHostingController<KeyboardView>?
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        configureKeyboardView()
        configureHeight()
        syncTraits()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint?.constant = traitCollection.verticalSizeClass == .compact
            ? Layout.compactHeight
            : Layout.regularHeight
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        syncTraits()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        syncTraits()
    }

    private func configureKeyboardView() {
        let rootView = KeyboardView(viewModel: viewModel, controller: self)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }

    private func configureHeight() {
        let constraint = view.heightAnchor.constraint(equalToConstant: Layout.regularHeight)
        constraint.priority = .defaultHigh
        constraint.isActive = true
        heightConstraint = constraint
    }

    private func syncTraits() {
        viewModel.syncTraits(
            keyboardType: textDocumentProxy.keyboardType ?? .default,
            returnKeyType: textDocumentProxy.returnKeyType ?? .default,
            needsInputModeSwitchKey: needsInputModeSwitchKey,
            documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
        )
    }
}

extension KeyboardViewController: KeyboardViewModelDelegate {
    func replaceComposition(previous: String, current: String) {
        for _ in previous {
            textDocumentProxy.deleteBackward()
        }
        if !current.isEmpty {
            textDocumentProxy.insertText(current)
        }
    }

    func insertCommittedText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    func replaceSelectedText(with text: String) {
        textDocumentProxy.insertText(text)
    }

    func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    func deleteForward() {
        if let selectedText = textDocumentProxy.selectedText, !selectedText.isEmpty {
            textDocumentProxy.insertText("")
            return
        }
        guard let after = textDocumentProxy.documentContextAfterInput, !after.isEmpty else {
            return
        }
        textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
        textDocumentProxy.deleteBackward()
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
    }

    func selectedTextInDocument() -> String? {
        textDocumentProxy.selectedText
    }

    func surroundingTextContext() -> (before: String, after: String) {
        (
            before: textDocumentProxy.documentContextBeforeInput ?? "",
            after: textDocumentProxy.documentContextAfterInput ?? ""
        )
    }
}
