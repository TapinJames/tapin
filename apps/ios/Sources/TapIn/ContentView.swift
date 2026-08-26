import SwiftUI
import FamilyControls
import DeviceActivity

struct ContentView: View {
    @StateObject private var viewModel = ClassModeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Authorization status
                GroupBox {
                    HStack {
                        Text("Screen Time:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(viewModel.authStatusText)
                            .foregroundStyle(viewModel.authStatusColor)
                    }
                } label: {
                    Label("Authorization", systemImage: "lock.shield")
                }

                // Allow Screen Time button
                if viewModel.authStatus != .approved {
                    Button {
                        Task {
                            await viewModel.requestAuthorization()
                        }
                    } label: {
                        Label("Allow Screen Time", systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                Divider()

                // Class mode status
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Class mode:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(viewModel.classModeStatusText)
                                .foregroundStyle(viewModel.isClassModeActive ? .green : .secondary)
                        }

                        if viewModel.isClassModeActive, let endTime = viewModel.classModeEndTime {
                            HStack {
                                Text("Ends at:")
                                Spacer()
                                Text(endTime, style: .time)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            // Countdown
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

                // Start/End buttons
                VStack(spacing: 12) {
                    // DEVELOPMENT ONLY — 60 seconds for testing
                    Button {
                        viewModel.startClassMode()
                    } label: {
                        Label("Start class mode (60 sec)", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.authStatus != .approved || viewModel.isClassModeActive)

                    Button {
                        viewModel.endClassMode()
                    } label: {
                        Label("End class mode now", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(!viewModel.isClassModeActive)
                }

                Spacer()

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
            .padding()
            .navigationTitle("Tap in")
            .onAppear {
                viewModel.checkAuthorizationStatus()
            }
        }
    }
}

#Preview {
    ContentView()
}
