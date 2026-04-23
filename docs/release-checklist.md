# Scribe Release Checklist

## Product

- Verify the start screen, live draft preview, and finished transcript screen on a real recording.
- Run one 5-10 minute clip and one 30+ minute clip to confirm the preview builds in order and the final transcript exports cleanly.
- Confirm the first-run model download messaging still feels clear on a fresh machine.

## Packaging

- Run `make app` and verify the Dock, Finder, and app bundle icon all use the final Scribe mark.
- Run `make dmg` and verify the DMG volume icon appears correctly.
- Open the DMG and confirm `Scribe.app` drags cleanly into `/Applications`.

## Repo

- Choose and add an open-source license before the public push.
- Initialize or connect the local folder to the final GitHub repo if it is not already under git.
- Add final screenshots and a short GIF after the first public release if needed.
- Review `README.md` one more time from a first-time visitor's perspective.

## Launch

- Publish `Scribe.dmg` in GitHub Releases.
- Use a short GitHub description: `Private transcription for people who work with words.`
- Lead the launch post with privacy, simplicity, and the newsroom use case.
- Cross-link Scribe from VoiceType, your Projects page, and the newsletter.

## Nice-to-have After Launch

- Add signed/notarized builds.
- Add screenshots and a hero GIF to the README.
- Add a small release notes section for each version.
