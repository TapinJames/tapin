import SwiftUI
import FamilyControls
import DeviceActivity
import NetworkExtension

struct ContentView: View {
    @StateObject private var classViewModel = ClassModeViewModel()
    @StateObject private var vpnManager = VPNManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Screen Time section
                    screenTimeSection

                    Divider()

                    // VPN section
                    vpnSection

                    Divider()

                    // Class mode section
                    classModeSection

                    // Blocked domains info
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Test domains that will be blocked:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("tiktok.com, instagram.com, snapchat.com, youtube.com, google.com, bing.com, duckduckgo.com")
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tap in")
            .onAppear {
                classViewModel.checkAuthorizationStatus()
                vpnManager.checkStopEvent()
            }
        }
    }

    // MARK: - Screen Time Section

    private var screenTimeSection: some View {
        VStack(spacing: 12) {
            GroupBox {
                HStack {
                    Text("Screen Time:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(classViewModel.authStatusText)
                        .foregroundStyle(classViewModel.authStatusColor)
                }
            } label: {
                Label("Screen Time", systemImage: "hourglass")
            }

            if classViewModel.authStatus != .approved {
                Button {
                    Task {
                        await classViewModel.requestAuthorization()
                    }
                } label: {
                    Label("Allow Screen Time", systemImage: "checkmark.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - VPN Section

    private var vpnSection: some View {
        VStack(spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DNS Filter:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(vpnStatusText)
                            .foregroundStyle(vpnStatusColor)
                    }

                    if vpnManager.isInstalled {
                        HStack {
                            Text("On-demand:")
                            Spacer()
                            Text("Enabled")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            } label: {
                Label("DNS Filter (VPN)", systemImage: "network")
            }

            // Stop event alert - only show when VPN is not connected
            if let stopEvent = vpnManager.lastStopEvent, vpnManager.status != .connected {
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Filter was turned off")
                                .fontWeight(.medium)
                        }
                        Text("At: \(stopEvent.stoppedAt)")
                            .font(.caption)
                        Text("Reason: \(stopEvent.reason)")
                            .font(.caption)

                        Button("Dismiss") {
                            vpnManager.clearStopEvent()
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                }
                .backgroundStyle(.orange.opacity(0.1))
            }

            // Install/Start/Stop buttons
            if !vpnManager.isInstalled || vpnManager.status == .disconnected || vpnManager.status == .invalid {
                Button {
                    Task {
                        try? await vpnManager.installAndStart()
                    }
                } label: {
                    Label("Install & start filter", systemImage: "shield.checkered")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if vpnManager.status == .connected {
                Button {
                    vpnManager.stop()
                } label: {
                    Label("Stop filter", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private var vpnStatusText: String {
        if !vpnManager.isInstalled {
            return "Not installed"
        }
        return vpnManager.status.description
    }

    private var vpnStatusColor: Color {
        switch vpnManager.status {
        case .connected:
            return .green
        case .connecting, .reasserting:
            return .orange
        case .disconnected, .disconnecting:
            return .red
        default:
            return .secondary
        }
    }

    // MARK: - Class Mode Section

    private var classModeSection: some View {
        VStack(spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Class mode:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(classViewModel.classModeStatusText)
                            .foregroundStyle(classViewModel.isClassModeActive ? .green : .secondary)
                    }

                    if classViewModel.isClassModeActive, let endTime = classViewModel.classModeEndTime {
                        HStack {
                            Text("Ends at:")
                            Spacer()
                            Text(endTime, style: .time)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        HStack {
                            Text("Time remaining:")
                            Spacer()
                            Text(endTime, style: .relative)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            } label: {
                Label("Class Mode (Apps)", systemImage: "book.closed")
            }

            // DEVELOPMENT ONLY — 60 seconds for testing
            Button {
                classViewModel.startClassMode()
            } label: {
                Label("Start class mode (60 sec)", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(classViewModel.authStatus != .approved || classViewModel.isClassModeActive)

            Button {
                classViewModel.endClassMode()
            } label: {
                Label("End class mode now", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!classViewModel.isClassModeActive)

            // Blocked apps info
            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Test apps that will be hidden:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Instagram, TikTok, Snapchat, YouTube")
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
