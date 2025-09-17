import SwiftUI

private struct NarrativeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Narrative")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("The quick brown fox jumps over the lazy dog while the city hums in the distance.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct VoiceLevelMeter: View {
    var level: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(
                        colors: [.green, .yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: proxy.size.width * level)
                    .animation(.smooth(duration: 0.2), value: level)
                HStack {
                    Text("Low")
                    Spacer()
                    Text("High")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            }
        }
        .frame(height: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Voice level")
        .accessibilityValue(levelDescription)
    }

    private var levelDescription: String {
        let percentage = Int(level * 100)
        return "Voice intensity at \(percentage) percent"
    }
}

private struct HoldToSpeakButton: View {
    let isRecording: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    @State private var didStartRecording = false

    var body: some View {
        label
            .contentShape(Capsule())
            .gesture(pressGesture)
            .accessibilityElement()
            .accessibilityLabel("Hold to speak")
            .accessibilityValue(isRecording ? "Recording" : "Idle")
            .accessibilityHint("Press and hold to record your narration.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                if isRecording {
                    onStop()
                    didStartRecording = false
                } else {
                    didStartRecording = true
                    onStart()
                }
            }
    }

    private var label: some View {
        Text(isRecording ? "Release to stop" : "Hold to speak")
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(isRecording ? Color.red : Color.blue)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !didStartRecording {
                    didStartRecording = true
                    onStart()
                }
            }
            .onEnded { _ in
                if didStartRecording {
                    onStop()
                }
                didStartRecording = false
            }
    }
}

struct HomeView: View {
    @StateObject private var recorder = SpeechPracticeRecorder()
    @StateObject private var analysisManager = SpeechAnalysisManager()
    @State private var showAnalysisPopup = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                NarrativeCard()

                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    Text("Voice Input")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    VoiceLevelMeter(level: recorder.level)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }

                Spacer(minLength: 24)

                HoldToSpeakButton(
                    isRecording: recorder.isRecording,
                    onStart: {
                        analysisManager.reset()
                        recorder.startRecording()
                    },
                    onStop: recorder.stopRecording
                )
            }
            .padding(24)
        }
        .task {
            recorder.requestPermission()
        }
        .alert("Microphone Access Needed", isPresented: permissionAlertBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
        .onChange(of: recorder.lastRecordingSummary) { _, summary in
            guard let summary else { return }
            Task {
                await analysisManager.analyze(summary: summary)
            }
        }
        .onChange(of: analysisManager.analysisText) { _, analysisText in
            if analysisText != nil {
                showAnalysisPopup = true
            }
        }
        .sheet(isPresented: $showAnalysisPopup) {
            AnalysisPopupView(analysisManager: analysisManager)
        }
    }


    private var permissionAlertBinding: Binding<Bool> {
        Binding(
            get: { recorder.presentPermissionAlert },
            set: { recorder.presentPermissionAlert = $0 }
        )
    }

    private var permissionAlertMessage: String {
        switch recorder.permission {
        case .undetermined:
            return "Please allow microphone access to start practicing."
        case .denied:
            return "Enable microphone access in Settings to record your narration."
        case .granted:
            return ""
        case .failed(let error):
            return "Recording failed: \(error.localizedDescription)"
        }
    }
}

struct AnalysisPopupView: View {
    @ObservedObject var analysisManager: SpeechAnalysisManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if analysisManager.isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Analyzing your narration...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("This may take a few moments")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let analysis = analysisManager.analysisText {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundStyle(.blue)
                                    .font(.title2)
                                Text("AI Feedback")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            Text(analysis)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                    }
                } else if let error = analysisManager.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.largeTitle)
                        Text("Analysis Error")
                            .font(.headline)
                        Text(error)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .navigationTitle("Voice Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
