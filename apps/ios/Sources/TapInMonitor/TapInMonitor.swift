import DeviceActivity
import os

/// DeviceActivityMonitor extension that applies and clears class mode blocks
/// based on scheduled time intervals.
///
/// iOS wakes this extension at the start and end of scheduled intervals,
/// even if the main app isn't running.
final class TapInMonitor: DeviceActivityMonitor {

    private let logger = Logger(subsystem: "com.tapinschools.tapin", category: "Monitor")

    /// Called when a scheduled interval starts.
    /// Apply the block immediately (idempotent with app's apply).
    override func intervalDidStart(for activity: DeviceActivityName) {
        logger.info("intervalDidStart: \(activity.rawValue)")
        ClassMode.applyDefault()
    }

    /// Called when a scheduled interval ends.
    /// Clear the block and stop monitoring.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        logger.info("intervalDidEnd: \(activity.rawValue)")
        ClassMode.clear()

        // Stop monitoring this activity since it's complete
        let center = DeviceActivityCenter()
        center.stopMonitoring([activity])
    }

    /// Called if the schedule or event changes while monitoring.
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        logger.info("eventDidReachThreshold: \(event.rawValue) for \(activity.rawValue)")
    }
}
