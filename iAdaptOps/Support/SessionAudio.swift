import AVFoundation
import Foundation
#if canImport(AudioToolbox)
import AudioToolbox
#endif

/// Cues for the guided session. Sounds are system sounds and the countdown is
/// spoken by the system voice, so the app ships no audio files and stays
/// completely offline. Everything mixes with whatever music is already playing,
/// which is only ducked while the voice is actually speaking.
@MainActor
final class SessionAudio: NSObject {
    static let shared = SessionAudio()

    private let synthesizer = AVSpeechSynthesizer()
    private var isSessionActive = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: Preferences

    private static let soundKey = "soundsEnabled"
    private static let voiceKey = "voiceEnabled"

    static var soundsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: soundKey) == nil ? true : UserDefaults.standard.bool(forKey: soundKey) }
        set { UserDefaults.standard.set(newValue, forKey: soundKey) }
    }

    static var voiceEnabled: Bool {
        get { UserDefaults.standard.object(forKey: voiceKey) == nil ? true : UserDefaults.standard.bool(forKey: voiceKey) }
        set { UserDefaults.standard.set(newValue, forKey: voiceKey) }
    }

    // MARK: Lifecycle

    /// The ducking category only takes effect while the session is active, so
    /// it is activated right before speaking and released once the voice
    /// falls silent, letting the user's music come straight back up.
    private func activateForSpeech() {
        guard !isSessionActive else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true)
        isSessionActive = true
    }

    private func releaseAudioSession() {
        guard isSessionActive else { return }
        isSessionActive = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func deactivate() {
        synthesizer.stopSpeaking(at: .immediate)
        releaseAudioSession()
    }

    // MARK: Cues

    enum Cue {
        case countdownTick
        case workStart
        case restStart
        case switchSide
        case finished

        /// Identifiers from the system sound library, so nothing is bundled.
        var systemSoundID: SystemSoundID {
            switch self {
            case .countdownTick: return 1103
            case .workStart: return 1113
            case .restStart: return 1114
            case .switchSide: return 1306
            case .finished: return 1025
            }
        }
    }

    func play(_ cue: Cue) {
        guard Self.soundsEnabled else { return }
        #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(cue.systemSoundID)
        #endif
    }

    func speak(_ text: String) {
        guard Self.voiceEnabled, !text.isEmpty else { return }
        activateForSpeech()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: LocalizationManager.shared.current.localeIdentifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.96
        utterance.preUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    func speak(key: String) {
        speak(t(key))
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension SessionAudio: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.releaseIfSilent() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.releaseIfSilent() }
    }

    private func releaseIfSilent() {
        guard !synthesizer.isSpeaking else { return }
        releaseAudioSession()
    }
}
