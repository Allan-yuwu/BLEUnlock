@main
struct Tests {
    static func main() {
        var count = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); count += 1 }
        check(DevicePauseAction.pause.pausesDevice, "pause targets paused state")
        check(!DevicePauseAction.resume.pausesDevice, "resume targets resumed state")
        check(!DevicePauseAction.pause.requiresChange(from: true), "repeat pause is a no-op")
        check(!DevicePauseAction.resume.requiresChange(from: false), "repeat resume is a no-op")
        check(DevicePauseAction.resume.requiresChange(from: true), "resume changes paused state")
        check(DevicePauseAction.pause.requiresChange(from: false), "pause changes active state")
        check(DevicePauseAction.pause.menuTitle("暂停", currentlyPaused: true) == "✅ 暂停", "paused checkmark labels current pause")
        check(DevicePauseAction.resume.menuTitle("恢复", currentlyPaused: true) == "恢复", "paused resume is action only")
        check(DevicePauseAction.pause.menuTitle("Pause", currentlyPaused: false) == "Pause", "active pause is action only")
        check(DevicePauseAction.resume.menuTitle("Resume", currentlyPaused: false) == "✅ Resume", "active checkmark labels current resume")
        check(DevicePauseAction(rawValue: 2) == nil, "invalid menu target rejected")
        let normal = DeviceParticipation()
        var paused = normal
        paused.setPaused(true)
        paused.acceptFreshSignal()
        paused.confirmCloseSignal()
        check(!paused.canParticipate && !paused.proximityConfirmed, "paused callbacks cannot rearm")
        var resumed = paused
        resumed.setPaused(false)
        check(!resumed.canParticipate, "resume cannot use cached proximity")
        let waitingPair = [.init(participation: resumed, nearby: true), .init(participation: normal, nearby: true)] as [DevicePresenceSnapshot]
        check(!aggregateDevicePresence(waitingPair, unlockAll: true, lockAny: false).unlock, "waiting member blocks all-close")
        check(aggregateDevicePresence(waitingPair, unlockAll: false, lockAny: false).unlock, "another fresh device permits any-close")
        resumed.acceptFreshSignal()
        check(resumed.canParticipate && !resumed.proximityConfirmed, "far sample must not unlock")
        func result(_ snapshots: [DevicePresenceSnapshot], _ all: Bool, _ any: Bool) -> (unlock: Bool, lock: Bool) {
            aggregateDevicePresence(snapshots, unlockAll: all, lockAny: any)
        }
        for all in [false, true] { for any in [false, true] {
            let empty = result([], all, any)
            check(!empty.unlock && !empty.lock, "zero devices")
            let excluded = result([.init(participation: paused, nearby: false)], all, any)
            check(!excluded.unlock && !excluded.lock, "all paused does not lock or unlock")
            let farResume = result([.init(participation: resumed, nearby: true)], all, any)
            check(!farResume.unlock && !farResume.lock, "far resumed sample waits for lock delay")
            let awayResume = result([.init(participation: resumed, nearby: false)], all, any)
            check(!awayResume.unlock && awayResume.lock, "timeout after resume locks")
            let mixed = result([.init(participation: paused, nearby: false), .init(participation: normal, nearby: true)], all, any)
            check(mixed.unlock && !mixed.lock, "paused device excluded from any/all")
            let mixedAway = result([.init(participation: paused, nearby: true), .init(participation: normal, nearby: false)], all, any)
            check(!mixedAway.unlock && mixedAway.lock, "paused nearby device cannot prevent remaining-away lock")
        }}
        resumed.confirmCloseSignal()
        check(result([.init(participation: resumed, nearby: true)], true, true).unlock, "fresh close rearms unlock")
        resumed.setPaused(true)
        check(!resumed.canParticipate, "pause again revokes proximity")
        print("Passed \(count) device pause / aggregation regression checks")
    }
}
