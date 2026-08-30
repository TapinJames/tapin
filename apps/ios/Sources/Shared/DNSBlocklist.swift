// DEVELOPMENT ONLY — served by the policy API from T-007

import Foundation

/// DNS domains to block during class mode.
/// In production, this list comes from the server's policy endpoint.
///
/// GUARDRAIL: Never add shared CDNs (akamai, akamaized.net, akamaihd.net,
/// cloudfront.net, fastly.net, googleapis.com, gstatic.com, etc.) — they
/// serve legitimate school sites (Canvas, Apple, etc.) and would cause
/// collateral blocking. Only block service-owned domains.
enum DNSBlocklist {
    /// Default blocklist for development testing.
    /// Blocks service-owned domains only — login/API calls fail even if
    /// some cached thumbnails from shared CDNs sneak through.
    static let defaultDomains: [String] = [
        // TikTok / ByteDance
        "tiktok.com",
        "tiktokv.com",
        "tiktokcdn.com",
        "tiktokcdn-us.com",
        "byteoversea.com",
        "ibyteimg.com",
        "muscdn.com",
        "musical.ly",
        "bytedance.com",
        "sgpstatp.com",
        "ttwstatic.com",
        "ibytedtos.com",

        // Instagram / Meta
        "instagram.com",
        "cdninstagram.com",
        "fbcdn.net",
        "fbsbx.com",
        "facebook.com",
        "fb.com",

        // Snapchat
        "snapchat.com",

        // YouTube / Google (search engines)
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
