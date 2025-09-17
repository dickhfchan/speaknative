import SwiftUI
import UIKit

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
            // Pre-warm the recorder to reduce first-tap latency
            recorder.preWarm()
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
    @StateObject private var audioPlayer = AudioPlayerManager()
    @Environment(\.dismiss) private var dismiss
    
    private let narrative = "The quick brown fox jumps over the lazy dog while the city hums in the distance."
    
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
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Steps Progress Section
                            stepsSection
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                            // Playback Controls Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Audio Playback")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                VStack(spacing: 12) {
                                    // Original Recording Playback (toggle stop only when this URL is playing)
                                    PlaybackButton(
                                        title: "Play Your Recording",
                                        icon: "mic.fill",
                                        color: .blue,
                                        isPlaying: (audioPlayer.isPlaying && audioPlayer.currentURL == analysisManager.lastRecordingURL),
                                        isLoading: false,
                                        action: {
                                            guard let recordingURL = analysisManager.lastRecordingURL else { return }
                                            if audioPlayer.isPlaying && audioPlayer.currentURL == recordingURL {
                                                audioPlayer.stop()
                                            } else {
                                                audioPlayer.play(url: recordingURL)
                                            }
                                        }
                                    )
                                    
                                    // Native Speaker Playback (auto play after generation, toggles to Stop)
                                    PlaybackButton(
                                        title: "Play Native Speaker",
                                        icon: "person.wave.2.fill",
                                        color: .green,
                                        isPlaying: (audioPlayer.isPlaying && audioPlayer.currentURL == analysisManager.nativeSpeakerAudioURL),
                                        isLoading: analysisManager.isGeneratingNativeAudio,
                                        action: {
                                            if audioPlayer.isPlaying && audioPlayer.currentURL == analysisManager.nativeSpeakerAudioURL {
                                                audioPlayer.stop()
                                            } else if let nativeURL = analysisManager.nativeSpeakerAudioURL {
                                                audioPlayer.play(url: nativeURL)
                                            } else {
                                                Task {
                                                    await analysisManager.generateNativeSpeakerAudio(for: narrative)
                                                }
                                            }
                                        }
                                    )

                                    // Analyze button: triggers auto-transcribe, compare, and display per-word issues
                                    Button(action: {
                                        Task { await analysisManager.runFullAnalysisFlow(narrative: narrative) }
                                    }) {
                                        HStack(spacing: 12) {
                                            if analysisManager.isComparing {
                                                ProgressView().scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "text.magnifyingglass")
                                                    .foregroundStyle(.white)
                                                    .font(.title3)
                                            }
                                            Text(analysisManager.isComparing ? "Analyzing..." : "Analyze Pronunciation")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8).fill(Color.purple)
                                        )
                                    }
                                    .disabled(
                                        analysisManager.isComparing ||
                                        analysisManager.isGeneratingNativeAudio ||
                                        analysisManager.lastRecordingURL == nil
                                    )
                                    
                                    if let error = analysisManager.nativeAudioError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            
                            // AI Feedback Section (only when available)
                            // Show results only after word-level comparison completes
                            if let feedback = analysisManager.wordLevelReport {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                            .foregroundStyle(.blue)
                                            .font(.title2)
                                        Text("Word-Level Issues")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Spacer()
                                    }

                                    Text(feedback)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)

                                    Button {
                                        UIPasteboard.general.string = feedback
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy Result")
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                    }
                }
                if let error = analysisManager.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                            .font(.largeTitle)
                        Text("Analysis Error")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ScrollView {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 200)
                            Button {
                                UIPasteboard.general.string = error
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Error")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            // Auto-play native audio once generated
            .onChange(of: analysisManager.nativeSpeakerAudioURL) { _, newURL in
                if let url = newURL {
                    audioPlayer.play(url: url)
                }
            }
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

// MARK: - Steps Section
private enum StepState {
    case pending
    case inProgress
    case done
}

extension AnalysisPopupView {
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Steps")
                .font(.headline)
                .foregroundStyle(.secondary)

            stepRow(title: "Record", state: stepStateRecord)
            stepRow(title: "Stop", state: stepStateStop)
            stepRow(title: "Generate native voice", state: stepStateGenerate)
            stepRow(title: "Compare", state: stepStateCompare)
            stepRow(title: "Display per-word issues", state: stepStateDisplay)
        }
    }

    private func stepRow(title: String, state: StepState) -> some View {
        HStack(spacing: 10) {
            switch state {
            case .done:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .inProgress:
                ProgressView().scaleEffect(0.8)
            case .pending:
                Image(systemName: "circle").foregroundStyle(.secondary)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private var stepStateRecord: StepState {
        analysisManager.lastRecordingURL != nil ? .done : .inProgress
    }

    private var stepStateStop: StepState {
        analysisManager.lastRecordingURL != nil ? .done : .pending
    }

    private var stepStateGenerate: StepState {
        if analysisManager.nativeSpeakerAudioURL != nil { return .done }
        return analysisManager.isGeneratingNativeAudio ? .inProgress : .pending
    }

    // Removed obsolete transcribe step

    private var stepStateCompare: StepState {
        if analysisManager.wordLevelReport != nil { return .done }
        return analysisManager.isComparing ? .inProgress : .pending
    }

    private var stepStateDisplay: StepState {
        analysisManager.wordLevelReport != nil ? .done : .pending
    }
}

struct PlaybackButton: View {
    let title: String
    let icon: String
    let color: Color
    let isPlaying: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isPlaying ? "stop.fill" : icon)
                        .foregroundStyle(.white)
                        .font(.title3)
                }
                
                Text(isLoading ? "Generating..." : (isPlaying ? "Stop" : title))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
            )
        }
        .disabled(isLoading)
    }
}

#Preview {
    HomeView()
}
