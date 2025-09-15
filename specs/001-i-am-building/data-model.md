# Data Model: Native American Accent Learning App

## Core Entities

### Narrative
**Purpose**: Short text passages that users read aloud
**Fields**:
- `id`: UUID (primary key)
- `title`: String (narrative title)
- `content`: String (text to be read)
- `difficulty`: Int (1-5 difficulty level)
- `duration`: TimeInterval (estimated reading time)
- `nativeAudioURL`: String (path to native speaker recording)
- `createdAt`: Date
- `updatedAt`: Date

**Validation Rules**:
- Content must be 50-500 characters
- Difficulty must be 1-5
- Native audio URL must be valid

### UserRecording
**Purpose**: Audio file of user's speech with metadata
**Fields**:
- `id`: UUID (primary key)
- `narrativeId`: UUID (foreign key to Narrative)
- `audioURL`: String (path to recorded audio file)
- `duration`: TimeInterval (recording duration)
- `quality`: String (audio quality assessment)
- `volume`: Float (average volume level)
- `createdAt`: Date
- `userId`: String (user identifier)

**Validation Rules**:
- Duration must be 5-300 seconds
- Quality must be "good", "fair", or "poor"
- Volume must be 0.0-1.0

### AnalysisResult
**Purpose**: Comparison data between user speech and native speaker
**Fields**:
- `id`: UUID (primary key)
- `recordingId`: UUID (foreign key to UserRecording)
- `overallScore`: Float (0.0-1.0 overall pronunciation score)
- `issues`: [PronunciationIssue] (array of identified issues)
- `processingTime`: TimeInterval (analysis duration)
- `confidence`: Float (0.0-1.0 confidence in analysis)
- `createdAt`: Date

**Validation Rules**:
- Overall score must be 0.0-1.0
- Confidence must be 0.0-1.0
- Issues array cannot be empty

### PronunciationIssue
**Purpose**: Specific pronunciation problems identified
**Fields**:
- `id`: UUID (primary key)
- `analysisResultId`: UUID (foreign key to AnalysisResult)
- `type`: String (vowel, consonant, stress, rhythm, intonation)
- `word`: String (problematic word)
- `position`: Int (character position in text)
- `severity`: Float (0.0-1.0 severity level)
- `description`: String (human-readable description)
- `suggestion`: String (improvement suggestion)

**Validation Rules**:
- Type must be valid pronunciation issue type
- Severity must be 0.0-1.0
- Word must not be empty

### Exercise
**Purpose**: Learning activity designed to practice specific pronunciation skills
**Fields**:
- `id`: UUID (primary key)
- `type`: String (word, phrase, sentence)
- `content`: String (text to practice)
- `targetIssue`: String (pronunciation issue this addresses)
- `difficulty`: Int (1-5 difficulty level)
- `audioURL`: String (path to native speaker example)
- `instructions`: String (how to perform exercise)
- `successCriteria`: String (what constitutes success)
- `createdAt`: Date

**Validation Rules**:
- Type must be "word", "phrase", or "sentence"
- Content must not be empty
- Difficulty must be 1-5
- Success criteria must be defined

### LearningPath
**Purpose**: Personalized sequence of exercises based on user's identified accent issues
**Fields**:
- `id`: UUID (primary key)
- `userId`: String (user identifier)
- `analysisResultId`: UUID (foreign key to AnalysisResult)
- `exercises`: [Exercise] (ordered list of exercises)
- `currentExerciseIndex`: Int (current position in path)
- `status`: String (active, completed, paused)
- `createdAt`: Date
- `updatedAt`: Date

**Validation Rules**:
- Current exercise index must be 0 to exercises.count-1
- Status must be valid learning path status
- Exercises array cannot be empty

### Progress
**Purpose**: User's completion status and performance metrics
**Fields**:
- `id`: UUID (primary key)
- `userId`: String (user identifier)
- `exerciseId`: UUID (foreign key to Exercise)
- `attempts`: Int (number of attempts)
- `success`: Bool (whether exercise was completed successfully)
- `score`: Float (0.0-1.0 performance score)
- `timeSpent`: TimeInterval (total time on exercise)
- `completedAt`: Date
- `createdAt`: Date

**Validation Rules**:
- Attempts must be >= 1
- Score must be 0.0-1.0
- Time spent must be positive

## Relationships

- `Narrative` 1:many `UserRecording`
- `UserRecording` 1:1 `AnalysisResult`
- `AnalysisResult` 1:many `PronunciationIssue`
- `AnalysisResult` 1:1 `LearningPath`
- `LearningPath` 1:many `Exercise` (through ordered relationship)
- `Exercise` 1:many `Progress`

## State Transitions

### LearningPath Status
- `active` → `paused` (user pauses learning)
- `paused` → `active` (user resumes learning)
- `active` → `completed` (all exercises completed)
- `completed` → `active` (new exercises added)

### Exercise Progress
- `not_started` → `in_progress` (user begins exercise)
- `in_progress` → `completed` (user succeeds)
- `in_progress` → `failed` (user fails)
- `failed` → `in_progress` (user retries)
- `completed` → `in_progress` (user practices again)
