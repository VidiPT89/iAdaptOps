import Foundation

/// Runs `work` but gives up after `limit`. A task group cannot do this here:
/// it waits for every child, and the database SDK does not stop its requests
/// when their task is cancelled, so a slow read would hold the group open.
@MainActor
func withTimeout<T>(_ limit: Duration, _ work: @escaping @MainActor () async throws -> T) async throws -> T {
    let gate = ResumeGate()
    return try await withCheckedThrowingContinuation { continuation in
        Task { @MainActor in
            do {
                let value = try await work()
                if gate.open() { continuation.resume(returning: value) }
            } catch {
                if gate.open() { continuation.resume(throwing: error) }
            }
        }
        Task { @MainActor in
            try? await Task.sleep(for: limit)
            if gate.open() { continuation.resume(throwing: CancellationError()) }
        }
    }
}

/// Makes sure a continuation is resumed exactly once.
@MainActor
private final class ResumeGate {
    private var isOpen = false

    func open() -> Bool {
        guard !isOpen else { return false }
        isOpen = true
        return true
    }
}
