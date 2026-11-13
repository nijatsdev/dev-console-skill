import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Focus").font(.largeTitle.bold())
            Text("Short sessions, long streaks.")
            Button("Get started") { model.finishOnboarding() }.buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
