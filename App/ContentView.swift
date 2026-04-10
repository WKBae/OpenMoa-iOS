import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.98, blue: 1.0),
                        Color(red: 0.93, green: 0.96, blue: 1.0),
                        Color.white,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        screenTitle
                        heroCard
                        stepsCard
                        constraintsCard
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom,
                        alignment: .topLeading
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, proxy.safeAreaInsets.top + 20)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 28)
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
        }
    }

    private var screenTitle: some View {
        Text("OpenMoa")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 6)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gesture-first Korean keyboard for iOS")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            Text("This host app exists to install and explain the custom keyboard extension. The keyboard itself lives in the OpenMoa Keyboard target.")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open App Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                UIApplication.shared.open(url)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
    }

    private var stepsCard: some View {
        infoCard(
            title: "Enable the keyboard",
            tint: Color(red: 0.91, green: 0.95, blue: 1.0)
        ) {
            Text("1. Build and install the app.")
            Text("2. Open Settings > General > Keyboard > Keyboards > Add New Keyboard.")
            Text("3. Pick OpenMoa Keyboard.")
            Text("4. Switch to it with the globe key from any text field.")
        }
    }

    private var constraintsCard: some View {
        infoCard(
            title: "iOS constraints",
            tint: Color(red: 0.98, green: 0.95, blue: 0.9)
        ) {
            Text("Custom keyboards use UIInputViewController and textDocumentProxy. Secure fields and some phone-oriented inputs fall back to the system keyboard.")
            Text("Selection-specific editing commands are limited by the platform, so this port prioritizes insertion, deletion, cursor movement, and clipboard basics.")
        }
    }

    private func infoCard<Content: View>(
        title: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .foregroundStyle(.secondary)
            .font(.system(size: 17, weight: .medium, design: .rounded))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
