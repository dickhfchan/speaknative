//
//  ContentView.swift
//  speaknative
//
//  Created by Dick Chan on 15/9/2025.
//

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

struct ContentView: View {
    @StateObject private var recorder = SpeechPracticeRecorder()
    @StateObject private var analysisManager = SpeechAnalysisManager()
    @State private var showingDiagnostics = false

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

                HStack {
                    Spacer()
                    Button {
                        showingDiagnostics = true
                    } label: {
                        Label("Diagnostics", systemImage: "wrench.and.screwdriver")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open diagnostics")
                    .accessibilityHint("Run connection tests")
                }

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

                analysisSection
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
        .onChange(of: recorder.lastRecordingSummary) { summary in
            guard let summary else { return }
            Task {
                await analysisManager.analyze(summary: summary)
            }
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView()
        }
    }

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if analysisManager.isAnalyzing {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Analyzing your narration...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let analysis = analysisManager.analysisText {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Feedback")
                        .font(.headline)
                    Text(analysis)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if let error = analysisManager.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
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

#Preview {
    ContentView()
}
