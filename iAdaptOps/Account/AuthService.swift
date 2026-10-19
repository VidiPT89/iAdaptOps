import AuthenticationServices
import CryptoKit
import FirebaseAuth
import GoogleSignIn
import UIKit

/// The signed-in person, reduced to what the screens show.
struct AccountUser: Equatable {
    let uid: String
    let name: String?
    let email: String?
    let providerIDs: [String]
    var isEmailVerified = false

    /// Mirrors `isAdmin()` in `firebase/firestore.rules`, which is what
    /// actually protects the data; this only decides what the app shows.
    var isAdmin: Bool {
        isEmailVerified && email?.lowercased() == AdminPolicy.email
    }

    var firstName: String? {
        name?.split(separator: " ").first.map(String.init)
    }

    /// Translation key for how the account signs in, shown in Settings.
    var providerLabelKey: String {
        if providerIDs.contains("apple.com") { return "auth.provider.apple" }
        if providerIDs.contains("google.com") { return "auth.provider.google" }
        if providerIDs.contains("microsoft.com") { return "auth.provider.microsoft" }
        return "auth.provider.email"
    }

    /// Used only by debug builds that ship without Firebase configuration.
    static let localGuest = AccountUser(uid: "local", name: nil, email: nil, providerIDs: [])
}

extension AccountUser {
    init(_ user: User) {
        self.init(
            uid: user.uid,
            name: user.displayName,
            email: user.email,
            providerIDs: user.providerData.map(\.providerID),
            isEmailVerified: user.isEmailVerified
        )
    }
}

/// Owns the Firebase session: email and password, Google, Microsoft and Apple
/// sign-in, sign-out and account deletion. Screens only read `phase`,
/// `isWorking` and `errorKey`.
@MainActor
@Observable
final class AuthService {
    enum Phase: Equatable {
        /// Built without Firebase configuration.
        case unavailable
        case signedOut
        case signedIn(AccountUser)
    }

    private(set) var phase: Phase
    private(set) var isWorking = false
    /// Translation key of the last failure, shown under the form.
    var errorKey: String?
    /// Translation key of a confirmation, such as a password reset email.
    var noticeKey: String?

    private var listener: AuthStateDidChangeListenerHandle?
    private var appleNonce: String?

    var user: AccountUser? {
        if case .signedIn(let user) = phase { return user }
        return nil
    }

    init() {
        guard FirebaseSetup.isConfigured else {
            phase = .unavailable
            return
        }
        phase = Auth.auth().currentUser.map { .signedIn(AccountUser($0)) } ?? .signedOut
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.phase = user.map { .signedIn(AccountUser($0)) } ?? .signedOut
            }
        }
    }

    #if DEBUG
    /// Lets a development build without Firebase configuration be used.
    func continueAsGuest() {
        guard phase == .unavailable else { return }
        phase = .signedIn(.localGuest)
    }
    #endif

    // MARK: - Email and password

    func signIn(email: String, password: String) async {
        await run {
            try await Auth.auth().signIn(withEmail: Self.clean(email), password: password)
        }
    }

    func signUp(name: String, email: String, password: String) async {
        await run {
            let result = try await Auth.auth().createUser(withEmail: Self.clean(email), password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            try await change.commitChanges()
            try? await result.user.sendEmailVerification()
            // The state listener fired before the name was set.
            self.phase = .signedIn(AccountUser(result.user))
        }
    }

    func sendPasswordReset(email: String) async {
        guard AuthValidation.isValidEmail(email) else {
            errorKey = "auth.error.invalidEmail"
            return
        }
        await run {
            try await Auth.auth().sendPasswordReset(withEmail: Self.clean(email))
            self.noticeKey = "auth.resetSent"
        }
    }

    // MARK: - Google

    func signInWithGoogle() async {
        guard FirebaseSetup.isGoogleAvailable else {
            errorKey = "auth.error.providerDisabled"
            return
        }
        guard let presenter = Self.topViewController() else { return }
        await run {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthFailure.missingToken
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
        }
    }

    // MARK: - Microsoft

    func signInWithMicrosoft() async {
        await run {
            let provider = OAuthProvider(providerID: "microsoft.com")
            provider.customParameters = ["prompt": "select_account"]
            provider.scopes = ["email", "profile"]
            let credential = try await provider.credential(with: nil)
            try await Auth.auth().signIn(with: credential)
        }
    }

    // MARK: - Apple

    func signInWithApple() async {
        errorKey = nil
        noticeKey = nil
        // The hashed nonce ties Apple's token to this one request.
        let nonce = Self.randomNonce()
        appleNonce = nonce
        let result: Result<ASAuthorization, Error>
        do {
            result = .success(try await AppleSignInRequest().perform { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = Self.sha256(nonce)
            })
        } catch {
            result = .failure(error)
        }
        await completeAppleRequest(result)
    }

    private func completeAppleRequest(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            report(error)
        case .success(let authorization):
            guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = appleNonce,
                  let tokenData = apple.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorKey = "auth.error.generic"
                return
            }
            await run {
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idToken,
                    rawNonce: nonce,
                    fullName: apple.fullName
                )
                let result = try await Auth.auth().signIn(with: credential)
                // Apple only shares the name on the very first sign-in.
                if result.user.displayName == nil, let name = Self.format(apple.fullName) {
                    let change = result.user.createProfileChangeRequest()
                    change.displayName = name
                    try? await change.commitChanges()
                    self.phase = .signedIn(AccountUser(result.user))
                }
            }
        }
    }

    // MARK: - Session

    /// Picks up changes made outside the app, such as the email being
    /// confirmed from the verification link, and refreshes the token the
    /// database rules read.
    func refreshUser() async {
        guard FirebaseSetup.isConfigured, let user = Auth.auth().currentUser else { return }
        try? await user.reload()
        _ = try? await user.getIDTokenResult(forcingRefresh: true)
        if let current = Auth.auth().currentUser {
            phase = .signedIn(AccountUser(current))
        }
    }

    func resendVerification() async {
        await run {
            try await Auth.auth().currentUser?.sendEmailVerification()
            self.noticeKey = "auth.verificationSent"
        }
    }

    func signOut() {
        guard FirebaseSetup.isConfigured else {
            phase = .unavailable
            return
        }
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
    }

    /// Deletes the account for good. `removeData` erases the cloud copy of
    /// the user's progress first, while the rules still let them reach it.
    /// Returns false when Firebase needs a fresh sign-in before deleting.
    func deleteAccount(removeData: () async throws -> Void) async -> Bool {
        guard FirebaseSetup.isConfigured, let user = Auth.auth().currentUser else { return false }
        // Apple accounts confirm with Apple once more: that is the fresh
        // sign-in Firebase wants, and it gives the code that revokes the
        // app's access to the Apple ID, as App Review requires.
        var appleCode: String?
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            guard let code = await reauthenticateWithApple() else { return false }
            appleCode = code
        } else {
            let lastSignIn = user.metadata.lastSignInDate ?? .distantPast
            guard Date().timeIntervalSince(lastSignIn) < 5 * 60 else {
                errorKey = "auth.error.recentLogin"
                return false
            }
        }
        var deleted = false
        await run {
            do {
                try await removeData()
            } catch {
                // Nothing was deleted; most often there is no connection.
                throw AuthFailure.cloudUnreachable
            }
            if let appleCode {
                // Only reaches Apple once the Apple key is set up in the
                // Firebase console; the account is deleted either way.
                try? await Auth.auth().revokeToken(withAuthorizationCode: appleCode)
            }
            // Looked up again rather than captured: the account object is
            // not safe to hand across to the SDK's own tasks.
            try await Auth.auth().currentUser?.delete()
            GIDSignIn.sharedInstance.signOut()
            deleted = true
        }
        return deleted
    }

    /// Signs in with Apple again for the current account. Returns Apple's
    /// one-time authorization code, or nil when it was cancelled or failed.
    private func reauthenticateWithApple() async -> String? {
        errorKey = nil
        let nonce = Self.randomNonce()
        do {
            let authorization = try await AppleSignInRequest().perform { request in
                request.nonce = Self.sha256(nonce)
            }
            guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = apple.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let codeData = apple.authorizationCode,
                  let code = String(data: codeData, encoding: .utf8)
            else {
                errorKey = "auth.error.generic"
                return nil
            }
            let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: nil)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            return code
        } catch {
            report(error)
            return nil
        }
    }

    // MARK: - Helpers

    private func run(_ work: () async throws -> Void) async {
        // Verification and password emails go out in the app's language.
        if FirebaseSetup.isConfigured {
            Auth.auth().languageCode = LocalizationManager.shared.current == .pt ? "pt-PT" : "en"
        }
        errorKey = nil
        noticeKey = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            report(error)
        }
    }

    private func report(_ error: Error) {
        let nsError = error as NSError
        // Closing a sign-in sheet is a choice, not a failure.
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue { return }
        if nsError.domain == kGIDSignInErrorDomain,
           nsError.code == GIDSignInError.canceled.rawValue { return }
        if case AuthFailure.cloudUnreachable = error {
            errorKey = "auth.error.network"
            return
        }
        errorKey = Self.messageKey(for: nsError)
    }

    private static func messageKey(for error: NSError) -> String? {
        // The project's Authentication has not been switched on in the
        // Firebase console: the server answers every sign-in with this, and
        // the SDK only reports it as an internal error.
        if AuthErrorDetails.isServiceNotConfigured(error) {
            return "auth.error.notConfigured"
        }
        guard error.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: error.code) else {
            return "auth.error.generic"
        }
        switch code {
        case .webContextCancelled: return nil
        case .invalidEmail: return "auth.error.invalidEmail"
        case .emailAlreadyInUse: return "auth.error.emailInUse"
        case .weakPassword: return "auth.error.weakPassword"
        case .wrongPassword, .userNotFound, .invalidCredential: return "auth.error.wrongCredentials"
        case .userDisabled: return "auth.error.userDisabled"
        case .networkError: return "auth.error.network"
        case .tooManyRequests: return "auth.error.tooManyRequests"
        case .accountExistsWithDifferentCredential: return "auth.error.otherProvider"
        case .requiresRecentLogin: return "auth.error.recentLogin"
        case .operationNotAllowed: return "auth.error.providerDisabled"
        default: return "auth.error.generic"
        }
    }

    private static func clean(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func format(_ components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let name = PersonNameComponentsFormatter().string(from: components)
        return name.isEmpty ? nil : name
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in charset.randomElement(using: &generator)! })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

private enum AuthFailure: Error {
    case missingToken
    case cloudUnreachable
}
