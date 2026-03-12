import Orion
import Foundation

private func isEnabled() -> Bool {
    let ud = UserDefaults.standard
    if ud.object(forKey: "com.trueshuffle.enabled") == nil {
        ud.set(true, forKey: "com.trueshuffle.enabled")
    }
    return ud.bool(forKey: "com.trueshuffle.enabled")
}

// When true, ALL URLs passing through SPTDataLoaderService get logged
// Toggle this via the com.trueshuffle.logurls UserDefault
private func isLogging() -> Bool {
    return UserDefaults.standard.bool(forKey: "com.trueshuffle.logurls")
}

struct TrueShuffleGroup: HookGroup {}

// MARK: - URL Logger
// Hooks SPTDataLoaderService to log every URL when logging is enabled
// Enable via: UserDefaults.standard.set(true, forKey: "com.trueshuffle.logurls")
// Then trigger shuffle in Spotify, export the debug log from EeveeSpotify settings

class URLLoggerHook: ClassHook<NSObject> {
    typealias Group = TrueShuffleGroup
    static let targetName = "SPTDataLoaderService"

    func URLSession(
        _ session: AnyObject,
        task: AnyObject,
        didCompleteWithError error: AnyObject?
    ) {
        if isLogging() {
            if let task = task as? URLSessionDataTask,
               let url = task.currentRequest?.url {
                writeDebugLog("[TrueShuffle-URL] \(url.absoluteString)")
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
