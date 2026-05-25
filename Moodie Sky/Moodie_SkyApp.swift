import SwiftUI
import SwiftData

@main
struct Moodie_SkyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: MoodEntry.self)
    }
}
