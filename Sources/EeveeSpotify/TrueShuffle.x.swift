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
