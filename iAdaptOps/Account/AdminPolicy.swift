import Foundation

/// The one administrator account. The same address is hard-coded in
/// `firebase/firestore.rules`; changing one means changing both.
enum AdminPolicy {
    static let email = "ividi.dev@gmail.com"
}
