import Foundation
import SwiftData

enum MoodiePreviewContainer {
  @MainActor
  static let container: ModelContainer = {
    let schema = Schema([MoodEntry.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
      let container = try ModelContainer(for: schema, configurations: [configuration])
      let context = container.mainContext
      let calendar = Calendar.current
      let now = Date()

      let samples: [(Int, String, String, String, Int)] = [
        (0, "맑음", "☀️", "아침 공기가 좋아서 조금 가볍게 시작했어요.", 4),
        (0, "구름", "☁️", "오후에는 생각이 많았지만 천천히 정리됐어요.", 3),
        (-1, "비", "🌧️", "조용히 쉬고 싶은 하루였어요.", 2),
        (-3, "무지개", "🌈", "작은 일이 기분을 확 밝혀줬어요.", 5),
      ]

      for sample in samples {
        let date = calendar.date(byAdding: .day, value: sample.0, to: now) ?? now
        context.insert(
          MoodEntry(
            date: date,
            weather: sample.1,
            emoji: sample.2,
            note: sample.3,
            intensity: sample.4
          )
        )
      }

      return container
    } catch {
      fatalError("Failed to create Moodie preview container: \(error)")
    }
  }()
}
