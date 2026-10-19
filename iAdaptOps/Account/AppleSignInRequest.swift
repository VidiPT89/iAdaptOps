import AuthenticationServices
import UIKit

/// Runs the system "Sign in with Apple" sheet and hands back its result.
/// Used instead of `SignInWithAppleButton` because that button is labelled
/// in the phone's language, not the one chosen inside the app.
@MainActor
final class AppleSignInRequest: NSObject {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    /// Held for the whole request: the controller does not keep itself
    /// alive, and a released one never calls back.
    private var controller: ASAuthorizationController?

    func perform(_ configure: (ASAuthorizationAppleIDRequest) -> Void) async throws -> ASAuthorization {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        configure(request)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        defer { self.controller = nil }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

extension AppleSignInRequest: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        MainActor.assumeIsolated {
            continuation?.resume(returning: authorization)
            continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        MainActor.assumeIsolated {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

extension AppleSignInRequest: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
    }
}
