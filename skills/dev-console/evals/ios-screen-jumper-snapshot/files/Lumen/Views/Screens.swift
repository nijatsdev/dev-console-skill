import SwiftUI

struct RootView: View {
    @Environment(Router.self) private var router
    var body: some View {
        @Bindable var router = router
        Group {
            switch router.route {
            case .onboarding1, .onboarding2, .onboarding3:
                Text("Onboarding \(router.route.rawValue.last.map(String.init) ?? "")")
            default:
                NavigationStack { Text(router.route.rawValue.capitalized).navigationTitle("Lumen") }
            }
        }
        .sheet(item: $router.sheet) { sheet in Text(sheet.rawValue) }
    }
}
