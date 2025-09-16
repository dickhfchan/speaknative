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
    @Binding var isRecording: Bool

    var body: some View {
        Button {
            isRecording.toggle()
        } label: {
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
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in
                    isRecording = true
                }
                .onEnded { _ in
                    isRecording = false
                }
        )
        .accessibilityAddTraits(.isButton)
    }
}

struct ContentView: View {
    @State private var voiceLevel: Double = 0.3
    @State private var isRecording: Bool = false

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
                    VoiceLevelMeter(level: voiceLevel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }

                Spacer(minLength: 24)

                HoldToSpeakButton(isRecording: $isRecording)
            }
            .padding(24)
        }
    }
}

#Preview {
    ContentView()
}
