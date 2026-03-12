import Orion
import Foundation

// MARK: - True Shuffle hook
// Hooks QueueTrackShuffledList.shuffledTracks and re-randomizes
// the weighted array Spotify returns using Fisher-Yates.

private let kTrueShuffleEnabled = "com.trueshuffle.enabled"

private func trueShuffleEnabled() -> Bool {
    return UserDefaults.standard.object(forKey: kTrueShuffleEnabled) as? Bool ?? true
}

// Fisher-Yates in-place shuffle on whatever NSArray Spotify returns
private func fisherYates(_ array: NSArray) -> NSArray {
    let mutable = array.mutableCopy() as! NSMutableArray
    var i = mutable.count - 1
    while i > 0 {
        let j = Int(arc4random_uniform(UInt32(i + 1)))
        mutable.exchangeObject(at: i, withObjectAt: j)
        i -= 1
    }
    return mutable.copy() as! NSArray
}

// QueueTrackShuffledList is the Swift class that owns the play queue order.
// Its mangled name is _TtC14Queue_ViewImpl22QueueTrackShuffledList.
// We hook shuffledTracks — the getter Spotify calls to build the queue.
class TrueShuffleQueueHook: ClassHook<NSObject> {
    typealias Group = TrueShuffleGroup

    static var targetName: String {
        "_TtC14Queue_ViewImpl22QueueTrackShuffledList"
    }

    func shuffledTracks() -> NSArray {
        let original = orig.shuffledTracks()
        guard trueShuffleEnabled(), original.count > 1 else {
            return original
        }
        return fisherYates(original)
    }
}

// MARK: - Group (shared with existing TrueShuffle hooks in TrueShuffle.x.swift)
struct TrueShuffleGroup: HookGroup {}
