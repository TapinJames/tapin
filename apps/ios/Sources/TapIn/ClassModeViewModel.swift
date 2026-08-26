import SwiftUI
import FamilyControls
import DeviceActivity
import os

/// ViewModel for the class mode test screen.
@MainActor
final class ClassModeViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.tapinschools.tapin", category: "ClassMode")

    /// Current authorization status.
    @Published private(set) var authStatus: AuthorizationStatus = .notDetermined

    /// Whether class mode is currently active.
    @Published private(set) var isClassModeActive: Bool = false

    /// When class mode will end (if active).
    @Published private(set) var classModeEndTime: Date?

    // DEVELOPMENT ONLY — 60 seconds for testing; production uses server-provided duration
    private let classModeSeconds: Int = 60

    // MARK: - Computed Properties

    var authStatusText: String {
        switch authStatus {
        case .notDetermined:
            return "Not requested"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }

    var authStatusColor: Color {
        switch authStatus {
        case .approved:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .secondary
        @unknown default:
            return .secondary
        }
    }

    var classModeStatusText: String {
        isClassModeActive ? "Active" : "Inactive"
    }

    // MARK: - Actions

    /// Check the current authorization status.
    func checkAuthorizationStatus() {
        authStatus = AuthorizationCenter.shared.authorizationStatus
        logger.info("Authorization status: \(String(describing: self.authStatus))")

        // Also check if class mode is currently active
        isClassModeActive = ClassMode.isActive
    }

    /// Request Screen Time authorization.
    func requestAuthorization() async {
        logger.info("Requesting Screen Time authorization...")
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authStatus = AuthorizationCenter.shared.authorizationStatus
            logger.info("Authorization result: \(String(describing: self.authStatus))")
        } catch {
            logger.error("Authorization failed: \(error.localizedDescription)")
            authStatus = AuthorizationCenter.shared.authorizationStatus
        }
    }

    /// Start class mode for the configured duration.
    func startClassMode() {
        logger.info("Starting class mode for \(self.classModeSeconds) seconds")

        // Apply blocks immediately
        ClassMode.applyDefault()

        // Calculate end time
        let now = Date()
        let endTime = now.addingTimeInterval(TimeInterval(classModeSeconds))
        classModeEndTime = endTime

        // Schedule the DeviceActivity monitor to clear blocks at end time
        scheduleMonitor(from: now, to: endTime)

        isClassModeActive = true
        logger.info("Class mode started, will end at \(endTime)")
    }

    /// End class mode immediately.
    func endClassMode() {
        logger.info("Ending class mode now")

        // Stop the scheduled monitor
        let center = DeviceActivityCenter()
        center.stopMonitoring([ClassMode.activityName])

        // Clear blocks
        ClassMode.clear()

        isClassModeActive = false
        classModeEndTime = nil
        logger.info("Class mode ended")
    }

    // MARK: - Private

    /// Schedule the DeviceActivity monitor for the class mode interval.
    private func scheduleMonitor(from start: Date, to end: Date) {
        let center = DeviceActivityCenter()

        // Create schedule components from dates
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: end)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        do {
            try center.startMonitoring(ClassMode.activityName, during: schedule)
            logger.info("Scheduled monitor from \(start) to \(end)")
        } catch {
            logger.error("Failed to schedule monitor: \(error.localizedDescription)")
        }
    }
}
