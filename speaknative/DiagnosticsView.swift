import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var azureStatus: TestStatus = .idle
    @State private var azureMessage: String?
    @State private var azureTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Azure OpenAI")) {
                    Button(action: testAzure) {
                        statusLabel("Test Azure OpenAI", status: azureStatus)
                    }
                    .disabled(azureStatus == .running)

                    if let message = azureMessage, !message.isEmpty {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(azureStatus == .success ? .primary : Color.red)
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
                let response = try await client.sendTestPrompt("Hi, how are you today?")

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