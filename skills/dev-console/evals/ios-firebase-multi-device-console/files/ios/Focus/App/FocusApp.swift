import SwiftUI
import FirebaseCore

@main
struct FocusApp: App {
    @State private var model = AppModel()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(model.colorScheme)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        switch model.screen {
        case .onboarding: OnboardingView()
        case .home: HomeView()
        }
    }
}
