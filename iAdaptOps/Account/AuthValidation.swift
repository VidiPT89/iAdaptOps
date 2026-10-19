import Foundation

/// Checks run on the sign-in form before anything is sent to the server, so
/// obvious mistakes get an instant, translated message.
enum AuthValidation {
    /// Firebase rejects anything shorter.
    static let minimumPasswordLength = 6

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    /// The translation key of the first problem with the form, or nil when it
    /// can be submitted.
    static func problemKey(name: String?, email: String, password: String) -> String? {
        if let name, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "auth.error.nameMissing"
        }
        if !isValidEmail(email) { return "auth.error.invalidEmail" }
        if password.count < minimumPasswordLength { return "auth.error.weakPassword" }
        return nil
    }
}
