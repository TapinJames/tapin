import Foundation

/// Shared App Group container for communication between app and extensions.
enum AppGroupContainer {
    static let identifier = "group.com.tapinschools.tapin"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    // MARK: - VPN Stop Event

    static var vpnStopEventURL: URL? {
        containerURL?.appendingPathComponent("vpn_stop_event.json")
    }

    /// Write a VPN stop event to the App Group.
    static func writeVPNStopEvent(reason: String, networkAvailable: Bool) {
        guard let url = vpnStopEventURL else { return }

        let event = VPNStopEvent(
            stoppedAt: ISO8601DateFormatter().string(from: Date()),
            reason: reason,
            networkAvailable: networkAvailable
        )

        do {
            let data = try JSONEncoder().encode(event)
            try data.write(to: url, options: .atomic)
        } catch {
            // Best effort - can't log in extension without os_log
        }
    }

    /// Read and optionally clear the VPN stop event.
    static func readVPNStopEvent(clear: Bool = false) -> VPNStopEvent? {
        guard let url = vpnStopEventURL else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let event = try JSONDecoder().decode(VPNStopEvent.self, from: data)

            if clear {
                try? FileManager.default.removeItem(at: url)
            }

            return event
        } catch {
            return nil
        }
    }

    // MARK: - Blocklist

    static var blocklistURL: URL? {
        containerURL?.appendingPathComponent("blocklist.json")
    }

    /// Read the blocklist from the App Group.
    static func readBlocklist() -> [String] {
        guard let url = blocklistURL else { return [] }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            return []
        }
    }

    /// Write the blocklist to the App Group.
    static func writeBlocklist(_ domains: [String]) {
        guard let url = blocklistURL else { return }

        do {
            let data = try JSONEncoder().encode(domains)
            try data.write(to: url, options: .atomic)
        } catch {
            // Best effort
        }
    }
}

/// VPN stop event persisted to App Group.
struct VPNStopEvent: Codable {
    let stoppedAt: String
    let reason: String
    let networkAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case stoppedAt = "stopped_at"
        case reason
        case networkAvailable = "network_available"
    }
}
