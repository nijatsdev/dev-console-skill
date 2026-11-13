import SwiftUI

@main
struct LumenApp: App {
    @State private var router = Router()
    var body: some Scene {
        WindowGroup {
            RootView().environment(router)
        }
    }
}
