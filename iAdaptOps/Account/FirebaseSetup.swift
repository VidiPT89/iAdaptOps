import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

/// Starts Firebase once, at launch, if the app was built with its
/// configuration file. Everything account-related checks `isConfigured`
/// first, so a build without the file still opens instead of crashing.
@MainActor
enum FirebaseSetup {
    private(set) static var isConfigured = false

    static func configure() {
        #if DEBUG
        if DebugLaunch.isGuest { return }
        #endif
        guard !isConfigured,
              Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        else { return }

        FirebaseApp.configure()

        // Keeps the account's data readable and writable offline; pending
        // writes are sent when the connection comes back.
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings

        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        isConfigured = true
    }

    /// Google Sign-In needs an OAuth client, which Firebase only creates once
    /// Google is enabled as a provider in the console.
    static var isGoogleAvailable: Bool {
        isConfigured && FirebaseApp.app()?.options.clientID != nil
    }

    /// Microsoft needs an Azure app registered in the Firebase console, which
    /// nothing in the config file reflects. Off until that is done, so nobody
    /// is offered a button that can only fail.
    static let isMicrosoftAvailable = false
}
