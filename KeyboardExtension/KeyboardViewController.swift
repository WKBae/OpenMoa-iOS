import Combine
import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
    private let viewModel = KeyboardViewModel()
    private var hostingController: UIHostingController<KeyboardView>?
    private var heightConstraint: NSLayoutConstraint?
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        let inputView = UIInputView(frame: .zero, inputViewStyle: .keyboard)
        inputView.allowsSelfSizing = true
        view = inputView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardPreferences.migrateLegacyValuesIfNeeded()
        viewModel.delegate = self
        observeViewModel()
        configureHeight()
        configureKeyboardView()
    }

    override func updateViewConstraints() {
        updateHeightConstraint()
        super.updateViewConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncTraits()
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
        hostingController.view.isOpaque = false

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
        let constraint = view.heightAnchor.constraint(equalToConstant: preferredKeyboardHeight)
        constraint.priority = .required
        constraint.isActive = true
        heightConstraint = constraint
    }

    private var preferredKeyboardHeight: CGFloat {
        metrics.preferredHeight(for: viewModel.mode)
    }

    private var metrics: KeyboardLayoutMetrics {
        let preferences = KeyboardPreferences.layoutValues
        return traitCollection.verticalSizeClass == .compact
            ? .compact(preferences: preferences)
            : .regular(preferences: preferences)
    }

    private func updateHeightConstraint() {
        // Apply the custom keyboard height before layout so the system default height does not flash first.
        heightConstraint?.constant = preferredKeyboardHeight
    }

    private func observeViewModel() {
        viewModel.$mode
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.view.setNeedsUpdateConstraints()
                self?.updateHeightConstraint()
            }
            .store(in: &cancellables)
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
