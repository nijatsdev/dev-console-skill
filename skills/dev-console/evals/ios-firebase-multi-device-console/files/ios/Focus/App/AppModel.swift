import SwiftUI
import Observation
import FirebaseAuth

@Observable
final class AppModel {
    enum Screen { case onboarding, home }

    var screen: Screen = Auth.auth().currentUser == nil ? .onboarding : .home
    /// nil follows the system setting.
    var colorScheme: ColorScheme? = nil

    func finishOnboarding() { screen = .home }
}
