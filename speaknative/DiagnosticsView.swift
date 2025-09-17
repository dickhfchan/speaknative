import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var azureStatus: TestStatus = .idle
    @State private var databaseStatus: TestStatus = .idle
    @State private var azureMessage: String?
    @State private var databaseMessage: String?
    @State private var azureTask: Task<Void, Never>?
    @State private var databaseTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section("Azure OpenAI") {
                    Button(action: testAzure) {
                        statusLabel("Test Azure OpenAI", status: azureStatus)
                    }
                    .disabled(azureStatus == .running)

                    if let message = azureMessage, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(azureStatus == .success ? .primary : .red)
                            .textSelection(.enabled)
                    }
                }

                Section("Database") {
                    Button(action: testDatabase) {
                        statusLabel("Test Database Connection", status: databaseStatus)
                    }
                    .disabled(databaseStatus == .running)

                    if let message = databaseMessage, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(databaseStatus == .success ? .primary : .red)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onDisappear {
                azureTask?.cancel()
                databaseTask?.cancel()
            }
            .listStyle(.insetGrouped)
        }
    }

    private func testAzure() {
        azureTask?.cancel()
        azureStatus = .running
        azureMessage = nil

        azureTask = Task {
            do {
                let client = try AzureOpenAIClient()
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("diagnostic.m4a")
                let summary = SpeechPracticeRecorder.RecordingSummary(
                    url: tempURL,
                    averageLevel: 0.55,
                    peakLevel: 0.82,
                    sampleCount: 120,
                    duration: 12
                )

                let response = try await client.analyze(summary: summary)

                await MainActor.run {
                    azureStatus = .success
                    azureMessage = response
                }
            } catch is CancellationError {
                // Ignore cancellation
            } catch {
                await MainActor.run {
                    azureStatus = .failure
                    azureMessage = error.localizedDescription
                }
            }
        }
    }

    private func testDatabase() {
        databaseTask?.cancel()
        databaseStatus = .running
        databaseMessage = nil

        databaseTask = Task {
            do {
                let response = try await DatabaseConnectivityTester.testConnection()
                await MainActor.run {
                    databaseStatus = .success
                    databaseMessage = response
                }
            } catch is CancellationError {
                // Ignore cancellation
            } catch {
                await MainActor.run {
                    databaseStatus = .failure
                    databaseMessage = error.localizedDescription
                }
            }
        }
    }

    private func statusLabel(_ title: String, status: TestStatus) -> some View {
        HStack {
            Text(title)
            Spacer()
            statusAccessory(status)
        }
    }

    @ViewBuilder
    private func statusAccessory(_ status: TestStatus) -> some View {
        switch status {
        case .idle:
            EmptyView()
        case .running:
            ProgressView()
                .progressViewStyle(.circular)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private enum TestStatus {
        case idle
        case running
        case success
        case failure
    }
}

#Preview {
    DiagnosticsView()
}
