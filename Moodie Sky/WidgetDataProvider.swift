import Foundation

// MARK: - 위젯용 공유 데이터 모델
// 앱이 기록을 저장/삭제할 때마다 UserDefaults(suiteName:)에 업데이트
// 위젯은 이 데이터만 읽으면 됨 — SwiftData 접근 불필요

enum MoodieWidgetData {
  static let suiteName = "group.com.mxvixxn.Moodie-Sky"

  // UserDefaults keys
  static let streakKey = "widget_current_streak"
  static let longestStreakKey = "widget_longest_streak"
  static let weeklyEntriesKey = "widget_weekly_entries"
  static let monthlyRecordedDaysKey = "widget_monthly_recorded_days"
  static let currentMonthKey = "widget_current_month"
  static let totalEntriesKey = "widget_total_entries"
  static let lastUpdateKey = "widget_last_update"

  static var shared: UserDefaults? {
    UserDefaults(suiteName: suiteName)
  }

  // MARK: - 주간 엔트리 (최근 7일)
  struct WeeklyEntry: Codable {
    let emoji: String
    let weather: String
    let note: String
    let date: Date
    let dayOfWeek: Int // 1=일, 2=월, ...
  }

  // MARK: - 위젯 데이터 쓰기 (앱에서 호출)
  static func update(
    currentStreak: Int,
    longestStreak: Int,
    weeklyEntries: [WeeklyEntry],
    monthlyRecordedDays: [Int], // 이번 달 기록 있는 날짜 (1, 2, 5, 10...)
    currentMonth: Date,
    totalEntries: Int
  ) {
    guard let defaults = shared else { return }

    defaults.set(currentStreak, forKey: streakKey)
    defaults.set(longestStreak, forKey: longestStreakKey)
    defaults.set(totalEntries, forKey: totalEntriesKey)
    defaults.set(Date(), forKey: lastUpdateKey)

    // 월간 기록 날짜
    defaults.set(monthlyRecordedDays, forKey: monthlyRecordedDaysKey)
    let monthComponents = Calendar.current.dateComponents([.year, .month], from: currentMonth)
    defaults.set("\(monthComponents.year ?? 2026)-\(monthComponents.month ?? 1)", forKey: currentMonthKey)

    // 주간 엔트리 (JSON)
    if let encoded = try? JSONEncoder().encode(weeklyEntries) {
      defaults.set(encoded, forKey: weeklyEntriesKey)
    }
  }

  // MARK: - 위젯 데이터 읽기 (위젯에서 호출)
  static func readStreak() -> (current: Int, longest: Int) {
    guard let defaults = shared else { return (0, 0) }
    return (defaults.integer(forKey: streakKey), defaults.integer(forKey: longestStreakKey))
  }

  static func readWeeklyEntries() -> [WeeklyEntry] {
    guard let defaults = shared,
          let data = defaults.data(forKey: weeklyEntriesKey),
          let entries = try? JSONDecoder().decode([WeeklyEntry].self, from: data)
    else { return [] }
    return entries
  }

  static func readMonthlyRecordedDays() -> (days: [Int], monthString: String) {
    guard let defaults = shared else { return ([], "") }
    let days = defaults.array(forKey: monthlyRecordedDaysKey) as? [Int] ?? []
    let month = defaults.string(forKey: currentMonthKey) ?? ""
    return (days, month)
  }

  static func readTotalEntries() -> Int {
    shared?.integer(forKey: totalEntriesKey) ?? 0
  }
}
