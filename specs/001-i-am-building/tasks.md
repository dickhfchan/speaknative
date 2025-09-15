# Tasks: Native American Accent Learning App

**Input**: Design documents from `/specs/001-i-am-building/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md, research.md, data-model.md, contracts/, quickstart.md
2. Generate tasks by category (Setup → Tests → Models → Services → UI → Integration → Polish)
3. Apply rules: Tests before implementation; Different files = [P]; Same file = sequential
4. Number tasks sequentially (T001, T002...)
5. Provide dependency notes and parallel execution examples
6. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions (current repo)
- App source: `speaknative/`
- Tests: `speaknativeTests/` (unit/integration/contract), `speaknativeUITests/`

---

## Phase 3.1: Setup
- [ ] T001 Initialize Azure OpenAI config and secrets handling in `speaknative/` (Info.plist keys, README setup)
- [ ] T002 Add logging utilities using OSLog in `speaknative/Logging/Logger.swift`
- [ ] T003 [P] Create Core Data stack boilerplate in `speaknative/Persistence/CoreDataStack.swift`
- [ ] T004 [P] Define shared error types in `speaknative/Support/AppError.swift`
- [ ] T005 Configure microphone permission rationale copy and flows in `speaknative/Support/Permissions.swift`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
Contract tests (from `contracts/speech-analysis-api.yaml`)
- [ ] T006 [P] Contract test analyzePronunciation 200 OK in `speaknativeTests/Contract/TestSpeechAnalysisContract.swift`
- [ ] T007 [P] Contract test error responses (401/429/500) in `speaknativeTests/Contract/TestSpeechAnalysisErrors.swift`

Integration tests (from user stories / quickstart)
- [ ] T008 [P] Integration test: narrative presentation flow in `speaknativeTests/Integration/TestNarrativeFlow.swift`
- [ ] T009 [P] Integration test: voice recording flow with permissions in `speaknativeTests/Integration/TestRecordingFlow.swift`
- [ ] T010 [P] Integration test: analysis results rendering within 2s in `speaknativeTests/Integration/TestAnalysisFlow.swift`
- [ ] T011 [P] Integration test: learning path generation and progression in `speaknativeTests/Integration/TestLearningPathFlow.swift`
- [ ] T012 [P] Integration test: failure yields additional exercises in `speaknativeTests/Integration/TestAdaptiveExercises.swift`
- [ ] T013 [P] Integration test: offline queue for analysis in `speaknativeTests/Integration/TestOfflineMode.swift`

UI tests (core journey)
- [ ] T014 [P] UI test: end-to-end journey (launch → record → analyze → exercises) in `speaknativeUITests/E2EJourneyTests.swift`

## Phase 3.3: Core Data Models (ONLY after tests are failing)
- [ ] T015 [P] Model `Narrative` in `speaknative/Models/Narrative.swift` (+ Core Data entity)
- [ ] T016 [P] Model `UserRecording` in `speaknative/Models/UserRecording.swift` (+ Core Data entity)
- [ ] T017 [P] Model `AnalysisResult` in `speaknative/Models/AnalysisResult.swift` (+ Core Data entity)
- [ ] T018 [P] Model `PronunciationIssue` in `speaknative/Models/PronunciationIssue.swift` (+ Core Data entity)
- [ ] T019 [P] Model `Exercise` in `speaknative/Models/Exercise.swift` (+ Core Data entity)
- [ ] T020 [P] Model `LearningPath` in `speaknative/Models/LearningPath.swift` (+ Core Data entity)
- [ ] T021 [P] Model `Progress` in `speaknative/Models/Progress.swift` (+ Core Data entity)

## Phase 3.4: Services (business logic)
- [ ] T022 VoiceRecordingService with AVFoundation in `speaknative/Services/VoiceRecordingService.swift`
- [ ] T023 Azure SpeechAnalysisService client (REST) in `speaknative/Services/SpeechAnalysisService.swift`
- [ ] T024 ExerciseService (generate exercises from issues) in `speaknative/Services/ExerciseService.swift`
- [ ] T025 ProgressService (persist and compute progress) in `speaknative/Services/ProgressService.swift`
- [ ] T026 OfflineQueueService (persist recordings for later analysis) in `speaknative/Services/OfflineQueueService.swift`

## Phase 3.5: ViewModels (MVVM)
- [ ] T027 [P] NarrativeViewModel in `speaknative/ViewModels/NarrativeViewModel.swift`
- [ ] T028 [P] RecordingViewModel in `speaknative/ViewModels/RecordingViewModel.swift`
- [ ] T029 [P] AnalysisViewModel in `speaknative/ViewModels/AnalysisViewModel.swift`
- [ ] T030 [P] ExerciseViewModel in `speaknative/ViewModels/ExerciseViewModel.swift`

## Phase 3.6: Views (SwiftUI)
- [ ] T031 NarrativeView (list/select narrative) in `speaknative/Views/NarrativeView.swift`
- [ ] T032 RecordingView (record, levels, timer) in `speaknative/Views/RecordingView.swift`
- [ ] T033 AnalysisView (score, issues, suggestions) in `speaknative/Views/AnalysisView.swift`
- [ ] T034 ExerciseView (word/phrase/sentence practice) in `speaknative/Views/ExerciseView.swift`
- [ ] T035 Wire into `ContentView.swift` navigation and app flow

## Phase 3.7: Integration & Error Handling
- [ ] T036 Permission handling flows and fallbacks in `speaknative/Support/Permissions.swift`
- [ ] T037 Error mapping from Azure API → user-friendly messages in `speaknative/Services/SpeechAnalysisService.swift`
- [ ] T038 Request/response logging and metrics in `speaknative/Support/Telemetry.swift`
- [ ] T039 Background upload/processing for queued analyses in `speaknative/Services/OfflineQueueService.swift`
- [ ] T040 Core Data migrations and lightweight schema strategy in `speaknative/Persistence/Migrations.md`

## Phase 3.8: Polish
- [ ] T041 [P] Unit tests: services (recording, analysis, exercise, progress) in `speaknativeTests/Unit/Services/`
- [ ] T042 [P] Unit tests: view models in `speaknativeTests/Unit/ViewModels/`
- [ ] T043 Performance tests: analysis turnaround and UI responsiveness in `speaknativeTests/Performance/`
- [ ] T044 Accessibility pass (VoiceOver, Dynamic Type) across `speaknative/Views/`
- [ ] T045 Documentation: setup and API usage in `specs/001-i-am-building/quickstart.md` and project README

---

## Dependencies
- Setup (T001–T005) before tests and implementation
- Tests (T006–T014) must be written and failing before T015+
- Models (T015–T021) before Services (T022–T026)
- Services before ViewModels (T027–T030)
- ViewModels before Views (T031–T035)
- Integration (T036–T040) after Services/Views are in place
- Polish (T041–T045) last

## Parallel Example
```
# Launch contract/integration tests together once setup is done:
Task: "Contract test analyzePronunciation 200 OK in speaknativeTests/Contract/TestSpeechAnalysisContract.swift"
Task: "Integration test analysis results rendering within 2s in speaknativeTests/Integration/TestAnalysisFlow.swift"
Task: "Integration test offline queue in speaknativeTests/Integration/TestOfflineMode.swift"

# Launch model creations in parallel (separate files):
Task: "Model Narrative in speaknative/Models/Narrative.swift"
Task: "Model UserRecording in speaknative/Models/UserRecording.swift"
Task: "Model AnalysisResult in speaknative/Models/AnalysisResult.swift"
```

## Validation Checklist
- [ ] All contracts have corresponding tests (T006–T007)
- [ ] All entities have model tasks (T015–T021)
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task
