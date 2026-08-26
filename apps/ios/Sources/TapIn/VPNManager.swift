import Foundation
import NetworkExtension
import os

/// Manages the VPN tunnel configuration and connection.
@MainActor
final class VPNManager: ObservableObject {
    private let logger = Logger(subsystem: "com.tapinschools.tapin", category: "VPNManager")

    /// Current VPN connection status
    @Published private(set) var status: NEVPNStatus = .invalid

    /// Whether the VPN configuration is installed
    @Published private(set) var isInstalled: Bool = false

    /// Last stop event read from App Group
    @Published private(set) var lastStopEvent: VPNStopEvent?

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?

    init() {
        loadConfiguration()
        observeStatus()
    }

    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public

    /// Install the VPN configuration and start the tunnel.
    func installAndStart() async throws {
        logger.info("Installing VPN configuration...")

        // Install default blocklist
        DNSBlocklist.installDefaultBlocklist()

        // Load or create manager
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        let manager: NETunnelProviderManager

        if let existing = managers.first {
            manager = existing
            logger.info("Using existing VPN configuration")
        } else {
            manager = NETunnelProviderManager()
            logger.info("Creating new VPN configuration")
        }

        // Configure protocol
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.tapinschools.tapin.tunnel"
        proto.serverAddress = "Tap in"

        manager.protocolConfiguration = proto
        manager.localizedDescription = "Tap in class mode"
        manager.isEnabled = true

        // On-demand: reconnect automatically after network changes and reboots
        let connectRule = NEOnDemandRuleConnect()
        connectRule.interfaceTypeMatch = .any
        manager.onDemandRules = [connectRule]
        manager.isOnDemandEnabled = true

        // Save configuration (triggers Apple's VPN permission prompt)
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()

        self.manager = manager
        isInstalled = true

        // Clear any previous stop event since we're starting fresh
        clearStopEvent()

        // Start the tunnel
        try manager.connection.startVPNTunnel()
        logger.info("VPN tunnel started")
    }

    /// Stop the tunnel and disable on-demand (for end of class mode).
    func stopAndDisable() async {
        logger.info("Stopping VPN tunnel and disabling on-demand...")

        guard let manager = manager else { return }

        // Disable on-demand so it doesn't reconnect
        manager.isOnDemandEnabled = false
        manager.onDemandRules = []

        do {
            try await manager.saveToPreferences()
            manager.connection.stopVPNTunnel()
            logger.info("VPN stopped and on-demand disabled")
        } catch {
            logger.error("Failed to disable on-demand: \(error.localizedDescription)")
            manager.connection.stopVPNTunnel()
        }
    }

    /// Reload the blocklist in the running tunnel.
    func reloadBlocklist() async {
        guard let session = manager?.connection as? NETunnelProviderSession else {
            return
        }

        do {
            try session.sendProviderMessage("reload".data(using: .utf8)!) { _ in }
            logger.info("Sent reload message to tunnel")
        } catch {
            logger.error("Failed to send reload message: \(error.localizedDescription)")
        }
    }

    /// Check for and read any VPN stop event from the App Group.
    func checkStopEvent() {
        lastStopEvent = AppGroupContainer.readVPNStopEvent(clear: false)
    }

    /// Clear the stop event after user acknowledges.
    func clearStopEvent() {
        _ = AppGroupContainer.readVPNStopEvent(clear: true)
        lastStopEvent = nil
    }

    // MARK: - Private

    private func loadConfiguration() {
        Task {
            do {
                let managers = try await NETunnelProviderManager.loadAllFromPreferences()
                if let existing = managers.first {
                    self.manager = existing
                    self.isInstalled = true
                    self.status = existing.connection.status
                    logger.info("Loaded existing VPN configuration, status: \(String(describing: self.status))")
                }
            } catch {
                logger.error("Failed to load VPN configuration: \(error.localizedDescription)")
            }
        }
    }

    private func observeStatus() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            self?.status = connection.status
            self?.logger.info("VPN status changed: \(String(describing: connection.status))")

            // Check for stop event when VPN disconnects
            if connection.status == .disconnected {
                self?.checkStopEvent()
            }
        }
    }
}

extension NEVPNStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid: return "Invalid"
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .reasserting: return "Reasserting"
        case .disconnecting: return "Disconnecting"
        @unknown default: return "Unknown"
        }
    }
}
