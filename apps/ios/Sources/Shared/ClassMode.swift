import Foundation
import ManagedSettings
import DeviceActivity

/// Manages Screen Time blocking for class mode.
/// Shared between the main app and the DeviceActivityMonitor extension.
final class ClassMode {

    /// The named store used for class mode settings.
    /// Using a named store ensures both app and extension operate on the same settings.
    private static let store = ManagedSettingsStore(named: .init("classMode"))

    /// The DeviceActivity name for class mode monitoring.
    static let activityName = DeviceActivityName("classMode")

    /// Apply blocks to the specified bundle identifiers.
    /// Apps with these bundle IDs will be hidden from the Home Screen and App Library.
    static func apply(bundleIds: [String]) {
        let applications = Set(bundleIds.compactMap { bundleId -> Application? in
            Application(bundleIdentifier: bundleId)
        })
        store.application.blockedApplications = applications
    }

    /// Apply blocks using the default development list.
    static func applyDefault() {
        apply(bundleIds: BlockedApps.bundleIdentifiers)
    }

    /// Clear all class mode blocks, returning apps to normal.
    static func clear() {
        store.application.blockedApplications = nil
    }

    /// Check if class mode is currently active (has blocked apps).
    static var isActive: Bool {
        guard let blocked = store.application.blockedApplications else {
            return false
        }
        return !blocked.isEmpty
    }
}
