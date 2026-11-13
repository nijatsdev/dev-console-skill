import SwiftUI
import Observation

@Observable
final class Router {
    enum Route: String, CaseIterable {
        case onboarding1, onboarding2, onboarding3
        case home, journal, entry, insights, calendar, profile, settings
    }
    enum Sheet: String, CaseIterable, Identifiable {
        case paywall, newEntry, moodPicker, share
        var id: String { rawValue }
    }

    var route: Route = .onboarding1
    var sheet: Sheet?

    func go(_ route: Route) { self.route = route }
    func present(_ sheet: Sheet) { self.sheet = sheet }
}
