import Orion
import Foundation

private func isEnabled() -> Bool {
    let ud = UserDefaults.standard
    if ud.object(forKey: "com.trueshuffle.enabled") == nil {
        ud.set(true, forKey: "com.trueshuffle.enabled")
    }
    return ud.bool(forKey: "com.trueshuffle.enabled")
}

private func isLogging() -> Bool {
    return UserDefaults.standard.bool(forKey: "com.trueshuffle.logurls")
}

struct TrueShuffleGroup: HookGroup {}

// MARK: - WebSocket frame logger
// Logs Ably WebSocket frames when logging is enabled so we can find the shuffle seed message

class TrueShuffleWebSocketHook: ClassHook<NSObject> {
    typealias Group = TrueShuffleGroup
    static let targetName = "ARTSRWebSocket"

    func _handleFrameWithData(_ data: NSData, opCode code: Int) {
        if isLogging(), code == 1,
           let text = String(data: data as Data, encoding: .utf8) {
            let lower = text.lowercased()
            if lower.contains("shuffle") || lower.contains("context") || lower.contains("queue") || lower.contains("seed") {
                writeDebugLog("[TrueShuffle-WS] \(text.prefix(500))")
            }
        }
        orig._handleFrameWithData(data, opCode: code)
    }
}

// MARK: - SPTFreeShuffleRecommendationsService

class RecsServiceHook: ClassHook<NSObject> {
    typealias Group = TrueShuffleGroup
    static let targetName = "SPTFreeShuffleRecommendationsService"

    func shuffledRecommendations() -> AnyObject? {
        return isEnabled() ? nil : orig.shuffledRecommendations()
    }

    func recommendedTracks() -> AnyObject? {
        return isEnabled() ? nil : orig.recommendedTracks()
    }

    func loadRecommendations() {
        if !isEnabled() { orig.loadRecommendations() }
    }

    func fetchRecommendations() {
        if !isEnabled() { orig.fetchRecommendations() }
    }
}

// MARK: - SPTSmartShuffleHandler

class SmartShuffleHandlerHook: ClassHook<NSObject> {
    typealias Group = TrueShuffleGroup
    static let targetName = "SPTSmartShuffleHandler"

    func isSmartShuffleAllowed() -> Bool {
        return isEnabled() ? false : orig.isSmartShuffleAllowed()
    }

    func isSmartShuffleSupported() -> Bool {
        return isEnabled() ? false : orig.isSmartShuffleSupported()
    }

    func isSmartShuffled() -> Bool {
        return isEnabled() ? false : orig.isSmartShuffled()
    }

    func isSmartShuffleExperimentEnabled() -> Bool {
        return isEnabled() ? false : orig.isSmartShuffleExperimentEnabled()
    }

    func canToggleSmartShuffle() -> Bool {
        return isEnabled() ? false : orig.canToggleSmartShuffle()
    }

    func enableSmartShuffle() {
        if !isEnabled() { orig.enableSmartShuffle() }
    }
}
