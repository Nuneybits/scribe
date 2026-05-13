import SwiftUI

/// Design tokens for the Top Strip redesign.
///
/// Two principles drive this palette:
/// 1. **Ink and paper.** Almost everything is `paper` (warm cream) or `ink` (near-black).
/// 2. **One accent.** Brand violet (`accent`) is the single colour used for
///    "alive" cues — status dots, the live caret, the active paragraph stamp,
///    drop-targeting feedback. Cyan (`cyan`) is reserved for the *Transcribing*
///    sweep at the very top of the window and the drop disc on the Start screen.
///    Nothing else uses cyan.
enum ScribeTheme {
    // ─── Surfaces ──────────────────────────────────────────────────────
    /// Warm cream paper that fills the entire window.
    static let paper        = Color(red: 246/255, green: 243/255, blue: 235/255) // #f6f3eb
    /// Pure white. Used only inside the error/warning banner card.
    static let surface      = Color.white
    /// Faintly inked surface for very subtle backgrounds.
    static let mutedSurface = Color(red: 27/255,  green: 24/255,  blue: 20/255).opacity(0.04)
    /// 6% black hairline — the resting state of the top strip.
    static let hairline     = Color.black.opacity(0.06)

    // ─── Ink ───────────────────────────────────────────────────────────
    /// Primary text and strong fills.
    static let ink          = Color(red: 27/255,  green: 24/255,  blue: 20/255) // #1b1814
    /// Secondary text — metadata, time codes, the export row.
    static let inkSoft      = Color(red: 91/255,  green: 82/255,  blue: 71/255) // #5b5247
    /// Faint ink — disabled states, "ahead" content.
    static let inkFaint     = Color(red: 27/255,  green: 24/255,  blue: 20/255).opacity(0.42)
    /// 10% black rule — dividers, borders.
    static let rule         = Color(red: 27/255,  green: 24/255,  blue: 20/255).opacity(0.10)

    // ─── Brand ─────────────────────────────────────────────────────────
    /// The single accent — status dots, active timestamps, the live caret.
    static let accent       = Color(red: 167/255, green: 139/255, blue: 255/255) // #a78bff violet
    static let accentSoft   = accent.opacity(0.18)
    /// Cyan companion. Used ONLY in the Transcribing sweep + the drop-disc gradient.
    static let cyan         = Color(red: 124/255, green: 208/255, blue: 255/255) // #7cd0ff
    /// Navy bottom of the drop-disc radial gradient.
    static let navy         = Color(red: 27/255,  green: 31/255,  blue: 59/255)  // #1b1f3b

    // ─── Status ────────────────────────────────────────────────────────
    static let success      = Color(red: 62/255,  green: 199/255, blue: 122/255) // #3ec77a
    static let warning      = Color(red: 181/255, green: 112/255, blue: 18/255)  // #b57012
    static let danger       = Color(red: 194/255, green: 41/255,  blue: 31/255)  // #c2291f

    // ─── Legacy aliases ────────────────────────────────────────────────
    // Kept so older call-sites continue to compile during the migration.
    static var background:    Color { paper }
    static var text:          Color { ink }
    static var secondaryText: Color { inkSoft }
    static var border:        Color { rule }
    static var strongRule:    Color { ink }
}
