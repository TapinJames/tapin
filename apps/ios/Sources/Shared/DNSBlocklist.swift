// DEVELOPMENT ONLY — served by the policy API from T-007

import Foundation

/// DNS domains to block during class mode.
/// In production, this list comes from the server's policy endpoint.
enum DNSBlocklist {
    /// Default blocklist for development testing.
    static let defaultDomains: [String] = [
        "tiktok.com",
        "instagram.com",
        "snapchat.com",
        "youtube.com",
        "www.google.com",
        "bing.com",
        "duckduckgo.com"
    ]

    /// Check if a domain should be blocked (suffix match).
    /// e.g., "api.tiktok.com" matches "tiktok.com"
    static func isBlocked(_ domain: String, blocklist: [String]) -> Bool {
        let lowercaseDomain = domain.lowercased()
        for blocked in blocklist {
            let lowercaseBlocked = blocked.lowercased()
            if lowercaseDomain == lowercaseBlocked ||
               lowercaseDomain.hasSuffix("." + lowercaseBlocked) {
                return true
            }
        }
        return false
    }

    /// Write the default blocklist to the App Group container.
    static func installDefaultBlocklist() {
        AppGroupContainer.writeBlocklist(defaultDomains)
    }
}
