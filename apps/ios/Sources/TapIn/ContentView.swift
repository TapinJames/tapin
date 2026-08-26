import SwiftUI
import FamilyControls
import DeviceActivity
import NetworkExtension

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()
    @StateObject private var classViewModel: ClassModeViewModel

    init() {
        let vpn = VPNManager()
        _vpnManager = StateObject(wrappedValue: vpn)
        _classViewModel = StateObject(wrappedValue: ClassModeViewModel(vpnManager: vpn))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Screen Time authorization section
                    screenTimeSection

                    Divider()

                    // Unified class mode section (Screen Time + VPN)
                    classModeSection

                    // Bypass alert - show if VPN was turned off during class mode
                    bypassAlertSection
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

    // MARK: - Class Mode Section (Unified)

    private var classModeSection: some View {
        VStack(spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // Class mode status
                    HStack {
                        Text("Class mode:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(classViewModel.classModeStatusText)
                            .foregroundStyle(classViewModel.isClassModeActive ? .green : .secondary)
                    }

                    // VPN status (part of class mode)
                    HStack {
                        Text("DNS filter:")
                        Spacer()
                        Text(vpnStatusText)
                            .foregroundStyle(vpnStatusColor)
                    }
                    .font(.subheadline)

                    if classViewModel.isClassModeActive, let endTime = classViewModel.classModeEndTime {
                        Divider()

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
                Label("Class Mode", systemImage: "book.closed")
            }

            // DEVELOPMENT ONLY — 15 seconds for testing
            Button {
                Task {
                    await classViewModel.startClassMode()
                }
            } label: {
                if classViewModel.isStartingVPN {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Start class mode (15 sec)", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(classViewModel.authStatus != .approved || classViewModel.isClassModeActive || classViewModel.isStartingVPN)

            Button {
                Task {
                    await classViewModel.endClassMode()
                }
            } label: {
                Label("End class mode", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!classViewModel.isClassModeActive)

            // What gets blocked info
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("During class mode:")
                        .font(.caption)
                        .fontWeight(.medium)

                    Text("• Apps hidden: Instagram, TikTok, Snapchat, YouTube")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("• Domains blocked: TikTok, Instagram, Facebook, Snapchat, YouTube, Google/Bing search")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Bypass Alert

    private var bypassAlertSection: some View {
        Group {
            // DEVELOPMENT ONLY — manual VPN stop if stuck
            if vpnManager.status == .connected && !classViewModel.isClassModeActive {
                Button {
                    Task {
                        await vpnManager.stopAndDisable()
                    }
                } label: {
                    Label("Stop VPN (stuck from previous test)", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.regular)
            }

            // Show if VPN was turned off (bypass attempt)
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
        }
    }

    // MARK: - Helpers

    private var vpnStatusText: String {
        if classViewModel.isStartingVPN {
            return "Starting..."
        }
        if !vpnManager.isInstalled {
            return "Off"
        }
        switch vpnManager.status {
        case .connected:
            return "On"
        case .connecting, .reasserting:
            return "Starting..."
        default:
            return "Off"
        }
    }

    private var vpnStatusColor: Color {
        switch vpnManager.status {
        case .connected:
            return .green
        case .connecting, .reasserting:
            return .orange
        default:
            return .secondary
        }
    }
}

#Preview {
    ContentView()
}
