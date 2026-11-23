// Manual exclusion is independent of proximity and of unverified watch state.
struct DeviceParticipation {
    private(set) var paused = false
    private(set) var awaitingFreshSignal = false
    private(set) var proximityConfirmed = true
    var canParticipate: Bool { !paused && !awaitingFreshSignal }

    mutating func setPaused(_ value: Bool) {
        paused = value
        awaitingFreshSignal = !value
        proximityConfirmed = false
    }

    mutating func confirmCloseSignal() {
        guard !paused else { return }
        proximityConfirmed = true
    }

    mutating func acceptFreshSignal() {
        guard !paused else { return }
        awaitingFreshSignal = false
    }
}

struct DevicePresenceSnapshot {
    var participation: DeviceParticipation
    var nearby: Bool
}

func aggregateDevicePresence(_ snapshots: [DevicePresenceSnapshot], unlockAll: Bool, lockAny: Bool) -> (unlock: Bool, lock: Bool) {
    let active = snapshots.filter { !$0.participation.paused }
    guard !active.isEmpty else { return (false, false) }
    let close: (DevicePresenceSnapshot) -> Bool = { $0.participation.canParticipate && $0.nearby && $0.participation.proximityConfirmed }
    return (unlockAll ? active.allSatisfy(close) : active.contains(where: close),
            lockAny ? active.contains { $0.participation.canParticipate && !$0.nearby } : active.allSatisfy { $0.participation.canParticipate && !$0.nearby })
}

// Explicit targets avoid turning an already-selected menu state into a toggle.
enum DevicePauseAction: Int {
    case resume = 0
    case pause = 1

    var pausesDevice: Bool { self == .pause }

    func requiresChange(from currentlyPaused: Bool) -> Bool {
        pausesDevice != currentlyPaused
    }

    func menuTitle(_ label: String, currentlyPaused: Bool) -> String {
        requiresChange(from: currentlyPaused) ? label : "✅ " + label
    }
}
