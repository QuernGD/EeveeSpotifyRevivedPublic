import Orion
import Foundation

private func isEnabled() -> Bool {
    let ud = UserDefaults.standard
    if ud.object(forKey: "com.trueshuffle.enabled") == nil {
        ud.set(true, forKey: "com.trueshuffle.enabled")
    }
    return ud.bool(forKey: "com.trueshuffle.enabled")
}

struct TrueShuffleGroup: HookGroup {}

// MARK: - Capture current playlist URI from network traffic
// We sniff the scrollsita/watch-feed URLs which always contain play_context_uri
// This gives us the current playlist URI without any extra hooks needed

class TrueShuffleURLCaptureHook: ClassHook<NSObject> {
    typealias Group = TrueShuffleGroup
    static let targetName = "SPTDataLoaderService"

    func URLSession(
        _ session: URLSession,
        task: URLSessionDataTask,
        didCompleteWithError error: Error?
    ) {
        if let url = task.currentRequest?.url?.absoluteString,
           let range = url.range(of: "play_context_uri=") {
            let after = String(url[range.upperBound...])
            let encoded = after.components(separatedBy: "&").first ?? after
            if let decoded = encoded.removingPercentEncoding,
               decoded.hasPrefix("spotify:playlist:") {
                lastKnownPlaylistURI = decoded
            }
        }
        orig.URLSession(session, task: task, didCompleteWithError: error)
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
