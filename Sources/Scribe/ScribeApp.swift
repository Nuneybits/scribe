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
        }
        .defaultSize(width: 960, height: 680)
        .windowToolbarStyle(.unifiedCompact)
    }
}
