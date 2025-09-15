# SpeakNative

An iOS app to help English learners improve American accent via narrative reading, voice recording, AI analysis (Azure OpenAI), and targeted exercises.

## Setup
- Xcode 15+, iOS 15+
- Add the following to app Info.plist:
  - AZURE_OPENAI_ENDPOINT (String)
  - AZURE_OPENAI_API_KEY (String)
  - AZURE_OPENAI_DEPLOYMENT (String)
- Run the app on a device/simulator with microphone access

## Highlights
- SwiftUI + MVVM, AVFoundation recording, Azure OpenAI analysis
- Offline queue for analysis, Core Data-ready stack

## Specs & Plan
See `specs/001-i-am-building/` for spec, plan, data model, contracts, quickstart, and tasks.
