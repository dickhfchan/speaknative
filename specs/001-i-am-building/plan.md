# Implementation Plan: Native American Accent Learning App

**Branch**: `001-i-am-building` | **Date**: 2025-01-27 | **Spec**: [link]
**Input**: Feature specification from `/specs/001-i-am-building/spec.md`

## Summary
Build an iOS app that helps English learners improve their American accent through voice recording, AI-powered pronunciation analysis, and personalized learning exercises. The app uses Azure OpenAI for speech analysis and provides progressive exercises from single words to sentences.

## Technical Context
**Language/Version**: Swift 5.7+  
**Primary Dependencies**: SwiftUI, Core Data, Combine, AVFoundation, Azure OpenAI SDK  
**Storage**: Core Data for local persistence  
**Testing**: XCTest for unit testing  
**Target Platform**: iOS 15.0+  
**Project Type**: mobile - iOS app with Azure OpenAI integration  
**Performance Goals**: 60fps UI, <2s voice analysis response time  
**Constraints**: Offline-capable core functionality, <100MB app size  
**Scale/Scope**: 1k+ users, 50+ narratives, 500+ exercises  

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simplicity**:
- Projects: [2] (iOS app, Azure OpenAI service)
- Using framework directly? (SwiftUI, Core Data, AVFoundation directly)
- Single data model? (Core Data model for all entities)
- Avoiding patterns? (No Repository/UoW - direct Core Data access)

**Architecture**:
- EVERY feature as library? (No - iOS app with modular components)
- Libraries listed: [Core modules: VoiceRecording, SpeechAnalysis, ExerciseEngine, ProgressTracking]
- CLI per library: [N/A - iOS app only]
- Library docs: [N/A - internal modules only]

**Testing (NON-NEGOTIABLE)**:
- RED-GREEN-Refactor cycle enforced? (Yes - TDD mandatory)
- Git commits show tests before implementation? (Yes)
- Order: Contract→Integration→E2E→Unit strictly followed? (Yes)
- Real dependencies used? (Azure OpenAI API, Core Data, AVFoundation)
- Integration tests for: voice recording, speech analysis, exercise completion
- FORBIDDEN: Implementation before test, skipping RED phase

**Observability**:
- Structured logging included? (Yes - OSLog framework)
- Frontend logs → backend? (Local logging only)
- Error context sufficient? (Yes - detailed error messages)

**Versioning**:
- Version number assigned? (1.0.0)
- BUILD increments on every change? (Yes)
- Breaking changes handled? (Core Data migration plan)

## Project Structure

### Documentation (this feature)
```
specs/001-i-am-building/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
ios/
├── SpeakNative/
│   ├── Models/
│   │   ├── Narrative.swift
│   │   ├── UserRecording.swift
│   │   ├── AnalysisResult.swift
│   │   ├── Exercise.swift
│   │   ├── LearningPath.swift
│   │   └── Progress.swift
│   ├── Services/
│   │   ├── VoiceRecordingService.swift
│   │   ├── SpeechAnalysisService.swift
│   │   ├── ExerciseService.swift
│   │   └── ProgressService.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── NarrativeView.swift
│   │   ├── RecordingView.swift
│   │   ├── AnalysisView.swift
│   │   └── ExerciseView.swift
│   ├── ViewModels/
│   │   ├── NarrativeViewModel.swift
│   │   ├── RecordingViewModel.swift
│   │   ├── AnalysisViewModel.swift
│   │   └── ExerciseViewModel.swift
│   └── Resources/
│       ├── CoreData/
│       └── Audio/
└── SpeakNativeTests/
    ├── Contract/
    ├── Integration/
    └── Unit/
```

**Structure Decision**: Option 3 - Mobile + API (iOS app with Azure OpenAI service)

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - Azure OpenAI SDK integration patterns
   - Voice recording best practices with AVFoundation
   - Speech analysis accuracy requirements
   - Core Data model design for learning progress
   - Offline capability implementation

2. **Generate and dispatch research agents**:
   ```
   Task: "Research Azure OpenAI SDK for iOS speech analysis integration"
   Task: "Find best practices for AVFoundation voice recording in iOS"
   Task: "Research speech analysis accuracy benchmarks for pronunciation"
   Task: "Investigate Core Data model design for learning progress tracking"
   Task: "Research offline-first architecture patterns for iOS apps"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `/scripts/bash/update-agent-context.sh cursor` for your AI assistant
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| 2 projects (iOS + Azure) | Azure OpenAI required for speech analysis | Local speech analysis insufficient accuracy |
| No library architecture | iOS app with modular components | Over-engineering for single-platform app |

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*