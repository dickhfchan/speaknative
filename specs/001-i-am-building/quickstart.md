# Quickstart Guide: Native American Accent Learning App

## Overview
This guide demonstrates the core user journey for the SpeakNative app, helping English learners improve their American accent through AI-powered pronunciation analysis and personalized exercises.

## Prerequisites
- iOS 15.0+ device
- Microphone permission granted
- Internet connection (for speech analysis)
- Azure OpenAI API key configured

## User Journey

### 1. App Launch
**Given** the user opens the app for the first time
**When** they see the welcome screen
**Then** they should see:
- App title "SpeakNative"
- "Start Learning" button
- Brief description of the app's purpose

### 2. Narrative Selection
**Given** the user taps "Start Learning"
**When** the narrative selection screen loads
**Then** they should see:
- List of available narratives
- Difficulty levels (1-5 stars)
- Estimated reading time
- "Select" button for each narrative

### 3. Narrative Reading
**Given** the user selects a narrative
**When** the narrative view loads
**Then** they should see:
- Narrative title
- Text content to read
- "Play Native Audio" button
- "Start Recording" button
- Progress indicator

### 4. Voice Recording
**Given** the user taps "Start Recording"
**When** the recording interface appears
**Then** they should see:
- Recording button (red circle)
- Timer showing recording duration
- "Stop Recording" button
- Audio level indicator

### 5. Speech Analysis
**Given** the user completes recording
**When** they tap "Stop Recording"
**Then** the app should:
- Show "Analyzing..." indicator
- Process the audio with Azure OpenAI
- Display analysis results within 2 seconds
- Show pronunciation score (0-100%)

### 6. Issue Identification
**Given** the analysis is complete
**When** the results screen loads
**Then** the user should see:
- Overall pronunciation score
- List of identified issues
- Specific words with problems
- Severity indicators for each issue

### 7. Learning Path Generation
**Given** the user views their analysis results
**When** they tap "Start Learning Path"
**Then** the app should:
- Generate personalized exercises
- Show exercise list (words → phrases → sentences)
- Display target issues for each exercise
- Provide "Begin" button for first exercise

### 8. Exercise Practice
**Given** the user begins an exercise
**When** the exercise view loads
**Then** they should see:
- Exercise instructions
- Text to practice
- "Play Example" button
- "Record" button
- Success criteria

### 9. Exercise Completion
**Given** the user completes an exercise
**When** they tap "Submit"
**Then** the app should:
- Analyze their performance
- Show pass/fail result
- Display improvement suggestions
- Enable "Next Exercise" or "Retry" button

### 10. Progress Tracking
**Given** the user completes multiple exercises
**When** they view their progress
**Then** they should see:
- Overall progress percentage
- Completed exercises count
- Remaining exercises
- Learning streak
- Achievement badges

## Success Criteria

### Functional Success
- [ ] User can record their voice successfully
- [ ] Speech analysis completes within 2 seconds
- [ ] Pronunciation issues are accurately identified
- [ ] Learning path is generated based on analysis
- [ ] Exercises are completed in correct order
- [ ] Progress is tracked and displayed

### Performance Success
- [ ] App launches in <3 seconds
- [ ] UI responds at 60fps
- [ ] Voice recording starts within 1 second
- [ ] Analysis completes within 2 seconds
- [ ] Exercise transitions are smooth

### User Experience Success
- [ ] Interface is intuitive for non-native speakers
- [ ] Instructions are clear and helpful
- [ ] Feedback is constructive and actionable
- [ ] Progress is motivating and visible
- [ ] App works offline for core features

## Error Scenarios

### Microphone Permission Denied
**Given** the user denies microphone permission
**When** they try to record
**Then** the app should:
- Show permission request dialog
- Explain why microphone is needed
- Provide settings link to enable permission

### Network Connectivity Issues
**Given** the user has no internet connection
**When** they try to analyze speech
**Then** the app should:
- Show offline mode message
- Store recording for later analysis
- Provide offline exercises if available

### Analysis Failure
**Given** the speech analysis fails
**When** the error occurs
**Then** the app should:
- Show user-friendly error message
- Provide retry option
- Fall back to basic feedback if possible

## Testing Checklist

### Manual Testing
- [ ] Test on iPhone (various sizes)
- [ ] Test on iPad
- [ ] Test with different accent levels
- [ ] Test with background noise
- [ ] Test with quiet/loud speech
- [ ] Test offline functionality
- [ ] Test accessibility features

### Automated Testing
- [ ] Unit tests for all services
- [ ] Integration tests for API calls
- [ ] UI tests for user flows
- [ ] Performance tests for analysis speed
- [ ] Memory tests for audio processing
