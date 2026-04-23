# Scribe

Private transcription for people who work with words.

Scribe is a local-first transcription app for Apple Silicon Macs. Drop in an audio file, get a readable transcript with paragraph breaks, click a paragraph to jump playback, and export the result as `.txt`, `.md`, or `.srt`.

## Highlights

- Native macOS app with a clean, readable transcript-first UI.
- Drag-and-drop support for Voice Memos, MP3s, WAVs, and other common formats.
- Local transcription through WhisperKit with a first-run model download.
- Paragraph-based transcript view with click-to-seek playback.
- Copy plus `.txt`, `.md`, and `.srt` export.
- Built for journalists, writers, researchers, and anyone working from recorded conversations.

## Why

Scribe is built around a few opinions:

- Privacy should be a feature, not a footnote.
- Journalists need simple tooling more than endless settings.
- The design should feel clean, modern, and calm.
- The tool should stay lightweight enough to open fast and get out of the way.

## Download

Build from source or package your own app bundle with the commands below. GitHub Releases should ship `Scribe.dmg`.

## Install

```bash
make app
```

That creates `dist/Scribe.app`.

## Build

```bash
CLANG_MODULE_CACHE_PATH=/tmp/scribe-clang-module-cache swift build --disable-sandbox
```

## Package a DMG

```bash
make dmg
```

That creates `dist/Scribe.dmg`.

## What Ships

- One-window macOS app
- Drag/drop audio intake
- Local WhisperKit transcription
- Live draft preview while longer files are processed
- Paragraph seek and playback controls
- `.txt`, `.md`, and `.srt` export

## Coming Soon

- Smarter first-run model selection
- Better partial transcript recovery for interrupted jobs
- Packaging/signing polish for public release
- Optional diarization in a later release

## How To

1. Drop in an audio file or click `Load Audio`.
2. Wait for the local model to prepare on first run.
3. Follow the live draft preview while the full transcript is built.
4. Click a timestamp to jump playback.
5. Copy the transcript or export it.

## Privacy

Scribe is designed to keep transcription local on your machine. There are no accounts, no telemetry hooks, and no cloud transcription path in this repo.

## Companion App

Scribe pairs naturally with VoiceType, but it stands on its own: VoiceType captures live thought, and Scribe helps turn recorded interviews, memos, and rough audio into usable copy.

## Permissions

- File access for dropped or selected audio files
- Local disk access for model download cache and transcript exports
- Audio playback via AVFoundation

## Tech Stack

- SwiftUI
- AVFoundation
- WhisperKit
- Swift Package Manager
