import SwiftUI

struct RecordingView: View {
    @StateObject var viewModel = RecordingViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.isRecording ? "Recording..." : "Ready")
            HStack {
                Button("Start") { viewModel.start() }
                Button("Stop") { viewModel.stop() }.disabled(!viewModel.isRecording)
            }
            if let url = viewModel.recordedURL { Text(url.lastPathComponent).font(.footnote) }
        }
        .padding()
        .navigationTitle("Record")
    }
}


