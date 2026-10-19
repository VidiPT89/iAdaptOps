import GoogleSignIn
import SwiftUI

@main
struct iAdaptOpsApp: App {
    init() {
        FirebaseSetup.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // Google Sign-In finishes by reopening the app on its URL scheme.
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
