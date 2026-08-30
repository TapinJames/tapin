// DEVELOPMENT ONLY — served by the policy API from T-007

import Foundation

/// Test bundle identifiers for class mode blocking.
/// In production, this list comes from the server's policy endpoint.
enum BlockedApps {
    static let bundleIdentifiers: [String] = [
        "com.burbn.instagram",           // Instagram
        "com.zhiliaoapp.musically",      // TikTok
        "com.toyopagroup.picaboo",       // Snapchat
        "com.google.ios.youtube"         // YouTube
    ]
}
