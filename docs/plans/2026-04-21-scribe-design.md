# Scribe v0.1.0 Design

Date: April 21, 2026

## Product statement

Scribe is a native macOS drag-and-drop transcription app for journalists, writers, researchers, and founders.

Drop an audio file. Get a readable transcript with paragraph breaks, honest progress, click-to-seek playback, and dead-simple exports. No cloud upload. No account. No telemetry. No busywork.

VoiceType is for what you say. Scribe is for what you hear.

## Strategic notes

- v0.1 optimizes for trust, readability, and speed to first transcript.
- The product should feel editorial and deliberate, not gadgety.
- The design language is modern, clean, functional, and quiet. Think museum utility, not faux-retro skeuomorphism.
- The differentiation is not "AI magic." It is private transcription for people who actually work with words.

## Platform and support

- Platform: macOS 14+
- Architecture target: Apple Silicon only for v0.1
- Packaging: unsigned DMG on GitHub Releases

### Why Apple Silicon only

WhisperKit is positioned by Argmax as an Apple Silicon framework, not a general Intel Mac transcription layer. We should not over-promise x86_64 compatibility in v0.1.

Apple began the Mac transition to Apple silicon on June 22, 2020, and Apple completed the hardware transition in June 2023 with the Apple silicon Mac Pro. That makes Intel support a legacy-tail concern, not a core-launch requirement.

We do not have a reliable public number for active Intel Mac market share, so we should not pretend we do. The safer product call is:

- ship the best local experience on modern Macs
- be explicit about Apple Silicon in the README, release notes, and website copy
- revisit Intel only if demand becomes real

## Architecture

- App shell: native SwiftUI macOS app
- Windowing: single-window app, no settings panel in v0.1
- Audio: AVFoundation for file loading, playback, duration, and seeking
- Transcription engine target: WhisperKit with a first-run English model download
- Persistence: none in v0.1 beyond model cache and user-selected export destinations
- State model: in-memory only for the current session

### Transcription model choice

Default target: WhisperKit with an English model chosen for a high-quality local experience on Apple Silicon.

Practical note:

- `openai_whisper-small.en` is roughly 487 MB in the WhisperKit model repo.
- compressed `small` variants also exist and may be better for first-run friction.

Implementation should preserve the ability to change the exact English model before release based on real-world performance testing.

## Core experience

### Primary workflow

1. User drops an `.m4a`, `.mp3`, `.wav`, or `.mov` file into the window, or clicks Load.
2. Scribe validates the file, loads the audio for playback, and begins transcription in the background.
3. Progress reflects processed audio, not a fake spinner.
4. Transcript appears as readable paragraphs.
5. Each paragraph is clickable and seeks playback to that paragraph's start time.
6. User copies the transcript or exports `.txt`, `.md`, or `.srt`.

### Product principles

- Keep the whole thing obvious in under 10 seconds.
- Do not bury the transcript behind configuration.
- Do not ask the user to understand models.
- Do not add extra surface area unless it materially improves the job to be done.

## UI

### Layout

One clean window with a minimum size of roughly 760 x 520 points and vertical resizing enabled.

Regions:

1. Header strip
2. File and status area
3. Playback transport and scrubber
4. Transcript pane
5. Export row or progress row

### Visual language

- Clean, museum-like, readable, and neutral
- Bright background or lightly tinted surface, not gamer-dark chrome
- Strong typography hierarchy
- Minimal ornament
- No visualizer
- No fake hardware-inspired chrome

### States

#### Empty

- Large drop target
- Short promise copy
- Load button

#### Transcribing

- File metadata visible
- Progress bar with percent and elapsed duration context
- Transcript pane may fill incrementally if the backend allows it

#### Ready

- Full transcript visible
- Playback controls active
- Export row visible

#### Partial failure

- Keep the partial transcript
- Show a soft warning strip
- Never clear useful text because an export or trailing segment failed

## Transcript model

### Segment

Each engine segment should preserve:

- `id`
- `text`
- `startTime`
- `endTime`

### Paragraph

Paragraphs are derived from segments using editorially useful heuristics:

- new paragraph when pause gap >= 1.2 seconds
- new paragraph when a paragraph reaches roughly 90 words
- preserve the first segment start time for seek behavior

Each paragraph should preserve:

- `id`
- `text`
- `startTime`
- `endTime`
- `segmentRange` or `segmentIDs`

## Playback behavior

- Load the dropped file into AVFoundation as soon as it is accepted
- Play, pause, stop, and seek are the only controls in v0.1
- Scrubber updates with playback position
- Clicking a paragraph seeks playback to that paragraph's `startTime`

## Export behavior

### `.txt`

- plain transcript
- paragraph breaks preserved

### `.md`

- paragraph breaks preserved
- optional timestamp prefix per paragraph

### `.srt`

- segment-level timestamps
- preserve timing fidelity from the transcription engine

## Error handling

### Unsupported file

Inline message:

`Can't read that file. Try .mp3, .m4a, .wav, or .mov.`

### Model download failure

- clear first-run explanation
- retry button
- state that the model is downloaded once and then used locally

### Mid-file transcription failure

- preserve partial transcript
- show warning strip
- allow copy/export of what exists

## Explicitly out of scope for v0.1

- speaker diarization
- summaries
- quote extraction
- search
- recent files
- libraries
- watch folders
- non-English models
- language picker
- settings panel
- telemetry
- accounts
- sync
- cloud processing
- auto-update
- Homebrew cask
- Windows
- iOS

These are feature pressure valves, not launch blockers.

## Testing

### Unit

- paragraph grouping
- timestamp formatting
- SRT serialization
- Markdown serialization

### Integration

- tiny local fixture set for pipeline sanity checks
- debug-only fixture runner is acceptable

### Manual

- one short clean file
- one iPhone Voice Memo around 45 minutes
- one rougher interview or field recording
- verify copy, seek, `.txt`, `.md`, `.srt`

## Distribution

- `Scribe.dmg` in GitHub Releases
- DMG contents:
  - `Scribe.app`
  - `/Applications` shortcut
  - `INSTALL FIRST.txt` matching VoiceType's install language

## README structure

README should mirror VoiceType's editorial rhythm:

- Highlights
- Download
- Install
- Why
- What Ships
- Coming Soon
- How To
- Privacy
- Permissions
- Tech Stack

## Launch positioning

### Tagline

For what you hear.

### Short description

Scribe is a local macOS transcription app for journalists and writers. Drop in a voice memo or interview, get back a readable transcript, and keep your audio off the cloud.

### Launch framing

VoiceType and Scribe should feel like two issues of the same magazine:

- same editorial tone
- same product values
- same visual system
- different jobs

## Implementation note

The current repo already contains useful macOS scaffolding, packaging scripts, and release structure. We should reuse that foundation while replacing the current UI and transcription flow with this cleaner transcript-first architecture.
