import Foundation

/// Reads what the sign-in SDK buries inside its errors.
enum AuthErrorDetails {
    /// True when the server says Authentication is not set up for the
    /// project (`CONFIGURATION_NOT_FOUND`), wherever in the error it appears.
    static func isServiceNotConfigured(_ error: NSError) -> Bool {
        var current: NSError? = error
        while let nsError = current {
            let text = [nsError.localizedDescription, "\(nsError.userInfo)"].joined(separator: " ")
            if text.contains("CONFIGURATION_NOT_FOUND") { return true }
            current = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return false
    }
}
