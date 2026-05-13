import AppKit
import SwiftUI

@main
struct ScribeApp: App {
    @State private var workspace = ScribeWorkspace()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView(workspace: workspace)
                .frame(minWidth: 760, minHeight: 520)
                .background(ScribeTheme.paper)
                .background(WindowConfigurator())
        }
        .defaultSize(width: 960, height: 680)
        // Hide the visible title bar so the hairline strip can sit flush
        // with the traffic lights. Traffic lights remain visible and the
        // window stays draggable from anywhere via WindowConfigurator.
        .windowStyle(.hiddenTitleBar)
    }
}

/// Reaches into AppKit to finish the title-bar treatment SwiftUI can't
/// express on its own: transparent titlebar, no title text, draggable from
/// anywhere, paper-coloured window background.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(ScribeTheme.paper)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
