import NetworkExtension
import os

/// Packet tunnel provider that filters DNS queries against a blocklist.
/// Blocked domains get NXDOMAIN; everything else is forwarded to upstream resolvers.
class PacketTunnelProvider: NEPacketTunnelProvider {

    private let logger = Logger(subsystem: "com.tapinschools.tapin.tunnel", category: "PacketTunnel")

    /// Blocklist loaded from App Group
    private var blocklist: [String] = []

    /// Upstream DNS resolvers
    private let upstreamResolvers = ["1.1.1.1", "8.8.8.8"]

    /// Stats for logging (no query names logged)
    private var blockedCount = 0
    private var forwardedCount = 0

    /// DNS forwarder for upstream queries
    private var dnsForwarder: DNSForwarder?

    // MARK: - Tunnel Lifecycle

    override func startTunnel(options: [String: NSObject]? = nil) async throws {
        logger.info("Starting tunnel...")

        // Load blocklist from App Group
        blocklist = AppGroupContainer.readBlocklist()
        if blocklist.isEmpty {
            // Install default blocklist if none exists
            DNSBlocklist.installDefaultBlocklist()
            blocklist = DNSBlocklist.defaultDomains
        }
        logger.info("Loaded blocklist with \(self.blocklist.count) domains")

        // Configure tunnel settings
        let settings = createTunnelSettings()
        try await setTunnelNetworkSettings(settings)

        // Initialize DNS forwarder
        dnsForwarder = DNSForwarder(resolvers: upstreamResolvers)

        // Start packet processing
        startPacketLoop()

        logger.info("Tunnel started successfully")
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        logger.info("Stopping tunnel with reason: \(String(describing: reason))")

        // Log stats
        logger.info("Session stats - blocked: \(self.blockedCount), forwarded: \(self.forwardedCount)")

        // Write stop event to App Group before completing
        let reasonString = stopReasonString(reason)
        let networkAvailable = reason != .noNetworkAvailable
        AppGroupContainer.writeVPNStopEvent(reason: reasonString, networkAvailable: networkAvailable)

        logger.info("Tunnel stopped")
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        // Handle "reload" message from app
        if let message = String(data: messageData, encoding: .utf8), message == "reload" {
            blocklist = AppGroupContainer.readBlocklist()
            logger.info("Reloaded blocklist with \(self.blocklist.count) domains")
            return "ok".data(using: .utf8)
        }
        return nil
    }

    // MARK: - Tunnel Configuration

    private func createTunnelSettings() -> NEPacketTunnelNetworkSettings {
        // Split tunnel: only DNS enters the tunnel
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.7.0.1")

        // IPv4: claim a private address, route only to our DNS server
        let ipv4 = NEIPv4Settings(addresses: ["10.7.0.2"], subnetMasks: ["255.255.255.255"])
        ipv4.includedRoutes = [NEIPv4Route(destinationAddress: "10.7.0.1", subnetMask: "255.255.255.255")]
        settings.ipv4Settings = ipv4

        // IPv6: explicitly disable to prevent DNS leaks over IPv6
        // This ensures all DNS goes through our IPv4 tunnel
        let ipv6 = NEIPv6Settings(addresses: [], networkPrefixLengths: [])
        ipv6.includedRoutes = []  // No IPv6 routes
        ipv6.excludedRoutes = [NEIPv6Route.default()]  // Exclude all IPv6
        settings.ipv6Settings = ipv6

        // DNS: we are the DNS server for all domains
        let dns = NEDNSSettings(servers: ["10.7.0.1"])
        dns.matchDomains = [""]  // Match all domains
        settings.dnsSettings = dns

        return settings
    }

    // MARK: - Packet Processing

    private func startPacketLoop() {
        packetFlow.readPackets { [weak self] packets, protocols in
            self?.handlePackets(packets, protocols: protocols)
            self?.startPacketLoop()  // Continue reading
        }
    }

    private func handlePackets(_ packets: [Data], protocols: [NSNumber]) {
        for (packet, proto) in zip(packets, protocols) {
            // We only handle IPv4 (AF_INET = 2)
            guard proto.int32Value == AF_INET else { continue }
            handleIPv4Packet(packet)
        }
    }

    private func handleIPv4Packet(_ packet: Data) {
        // Minimum IPv4 header is 20 bytes
        guard packet.count >= 20 else { return }

        // Parse IPv4 header
        let headerLength = Int(packet[0] & 0x0F) * 4
        guard packet.count >= headerLength + 8 else { return }  // Need UDP header too

        // Check protocol (17 = UDP)
        let proto = packet[9]
        guard proto == 17 else { return }

        // Parse UDP header
        let udpStart = headerLength
        let destPort = UInt16(packet[udpStart + 2]) << 8 | UInt16(packet[udpStart + 3])

        // Only handle DNS (port 53)
        guard destPort == 53 else { return }

        // Parse DNS query
        let dnsStart = udpStart + 8
        guard packet.count > dnsStart else { return }
        let dnsData = packet.subdata(in: dnsStart..<packet.count)

        handleDNSQuery(dnsData, originalPacket: packet)
    }

    private func handleDNSQuery(_ dnsData: Data, originalPacket: Data) {
        // Parse DNS question
        guard let (transactionId, queryName, queryType) = parseDNSQuestion(dnsData) else {
            return
        }

        // Check if blocked
        if DNSBlocklist.isBlocked(queryName, blocklist: blocklist) {
            blockedCount += 1
            // Send NXDOMAIN response
            if let response = buildNXDOMAINResponse(transactionId: transactionId, query: dnsData) {
                sendDNSResponse(response, originalPacket: originalPacket)
            }
        } else {
            forwardedCount += 1
            // Forward to upstream resolver
            forwardDNSQuery(dnsData, originalPacket: originalPacket)
        }
    }

    // MARK: - DNS Parsing

    private func parseDNSQuestion(_ data: Data) -> (UInt16, String, UInt16)? {
        // DNS header is 12 bytes
        guard data.count >= 12 else { return nil }

        let transactionId = UInt16(data[0]) << 8 | UInt16(data[1])

        // Parse question section (starts at byte 12)
        var offset = 12
        var nameParts: [String] = []

        while offset < data.count {
            let length = Int(data[offset])
            if length == 0 {
                offset += 1
                break
            }
            guard offset + 1 + length <= data.count else { return nil }
            let part = String(data: data.subdata(in: (offset + 1)..<(offset + 1 + length)), encoding: .utf8) ?? ""
            nameParts.append(part)
            offset += 1 + length
        }

        // Query type (2 bytes after name)
        guard offset + 2 <= data.count else { return nil }
        let queryType = UInt16(data[offset]) << 8 | UInt16(data[offset + 1])

        let queryName = nameParts.joined(separator: ".")
        return (transactionId, queryName, queryType)
    }

    private func buildNXDOMAINResponse(transactionId: UInt16, query: Data) -> Data? {
        // Copy the query and modify it to be an NXDOMAIN response
        guard query.count >= 12 else { return nil }

        var response = query

        // Set response flags: QR=1 (response), RCODE=3 (NXDOMAIN)
        // Flags are at bytes 2-3
        response[2] = 0x81  // QR=1, Opcode=0, AA=0, TC=0, RD=1
        response[3] = 0x83  // RA=1, Z=0, RCODE=3 (NXDOMAIN)

        // Answer count = 0 (bytes 6-7)
        response[6] = 0
        response[7] = 0

        return response
    }

    // MARK: - DNS Forwarding

    private func forwardDNSQuery(_ query: Data, originalPacket: Data) {
        dnsForwarder?.forward(query: query) { [weak self] response in
            guard let response = response else { return }
            self?.sendDNSResponse(response, originalPacket: originalPacket)
        }
    }

    private func sendDNSResponse(_ dnsResponse: Data, originalPacket: Data) {
        // Build response packet by swapping src/dst addresses and ports
        guard originalPacket.count >= 28 else { return }  // IP header + UDP header

        let headerLength = Int(originalPacket[0] & 0x0F) * 4

        var responsePacket = Data()

        // IP header (swap src and dst)
        var ipHeader = originalPacket.subdata(in: 0..<headerLength)

        // Swap source and destination IP addresses (bytes 12-15 and 16-19)
        let srcIP = ipHeader.subdata(in: 12..<16)
        let dstIP = ipHeader.subdata(in: 16..<20)
        ipHeader.replaceSubrange(12..<16, with: dstIP)
        ipHeader.replaceSubrange(16..<20, with: srcIP)

        // Update total length
        let totalLength = UInt16(headerLength + 8 + dnsResponse.count)
        ipHeader[2] = UInt8(totalLength >> 8)
        ipHeader[3] = UInt8(totalLength & 0xFF)

        // Calculate IP header checksum
        ipHeader[10] = 0
        ipHeader[11] = 0
        let checksum = calculateIPChecksum(ipHeader)
        ipHeader[10] = UInt8(checksum >> 8)
        ipHeader[11] = UInt8(checksum & 0xFF)

        responsePacket.append(ipHeader)

        // UDP header (swap ports)
        let udpStart = headerLength
        var udpHeader = originalPacket.subdata(in: udpStart..<(udpStart + 8))
        let srcPort = udpHeader.subdata(in: 0..<2)
        let dstPort = udpHeader.subdata(in: 2..<4)
        udpHeader.replaceSubrange(0..<2, with: dstPort)
        udpHeader.replaceSubrange(2..<4, with: srcPort)

        // Update UDP length
        let udpLength = UInt16(8 + dnsResponse.count)
        udpHeader[4] = UInt8(udpLength >> 8)
        udpHeader[5] = UInt8(udpLength & 0xFF)

        // Clear UDP checksum
        udpHeader[6] = 0
        udpHeader[7] = 0

        responsePacket.append(udpHeader)

        // DNS response
        responsePacket.append(dnsResponse)

        // Write back to tunnel
        packetFlow.writePackets([responsePacket], withProtocols: [NSNumber(value: AF_INET)])
    }

    // MARK: - Helpers

    private func calculateIPChecksum(_ header: Data) -> UInt16 {
        var sum: UInt32 = 0
        let count = header.count

        // Sum all 16-bit words
        var i = 0
        while i < count - 1 {
            let word = UInt32(header[i]) << 8 | UInt32(header[i + 1])
            sum += word
            i += 2
        }

        // Add odd byte if present
        if count % 2 == 1 {
            sum += UInt32(header[count - 1]) << 8
        }

        // Fold 32-bit sum to 16 bits
        while sum >> 16 != 0 {
            sum = (sum & 0xFFFF) + (sum >> 16)
        }

        return ~UInt16(sum)
    }

    private func stopReasonString(_ reason: NEProviderStopReason) -> String {
        switch reason {
        case .none: return "none"
        case .userInitiated: return "userInitiated"
        case .providerFailed: return "providerFailed"
        case .noNetworkAvailable: return "noNetworkAvailable"
        case .unrecoverableNetworkChange: return "unrecoverableNetworkChange"
        case .providerDisabled: return "providerDisabled"
        case .authenticationCanceled: return "authenticationCanceled"
        case .configurationFailed: return "configurationFailed"
        case .idleTimeout: return "idleTimeout"
        case .configurationDisabled: return "configurationDisabled"
        case .configurationRemoved: return "configurationRemoved"
        case .superceded: return "superceded"
        case .userLogout: return "userLogout"
        case .userSwitch: return "userSwitch"
        case .connectionFailed: return "connectionFailed"
        case .sleep: return "sleep"
        case .appUpdate: return "appUpdate"
        @unknown default: return "unknown"
        }
    }
}
