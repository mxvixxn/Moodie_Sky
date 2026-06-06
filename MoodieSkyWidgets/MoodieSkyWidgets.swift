import WidgetKit
import SwiftUI

// MARK: - 공유 데이터 읽기 (앱의 WidgetDataProvider와 같은 구조)

enum MoodieWidgetData {
  static let suiteName = "group.com.mxvixxn.Moodie-Sky"

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

  struct WeeklyEntry: Codable {
    let emoji: String
    let weather: String
    let note: String
    let date: Date
    let dayOfWeek: Int
  }

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

// MARK: - Timeline Provider

struct MoodieTimelineEntry: TimelineEntry {
  let date: Date
  let currentStreak: Int
  let longestStreak: Int
  let weeklyEntries: [MoodieWidgetData.WeeklyEntry]
  let monthlyRecordedDays: [Int]
  let monthString: String
  let totalEntries: Int
}

struct MoodieTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> MoodieTimelineEntry {
    MoodieTimelineEntry(
      date: Date(),
      currentStreak: 7,
      longestStreak: 21,
      weeklyEntries: [],
      monthlyRecordedDays: [1, 2, 3, 5, 6],
      monthString: "2026-6",
      totalEntries: 42
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (MoodieTimelineEntry) -> Void) {
    completion(makeEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MoodieTimelineEntry>) -> Void) {
    let entry = makeEntry()
    // 30분마다 갱신
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
  }

  private func makeEntry() -> MoodieTimelineEntry {
    let streak = MoodieWidgetData.readStreak()
    let weekly = MoodieWidgetData.readWeeklyEntries()
    let monthly = MoodieWidgetData.readMonthlyRecordedDays()
    let total = MoodieWidgetData.readTotalEntries()

    return MoodieTimelineEntry(
      date: Date(),
      currentStreak: streak.current,
      longestStreak: streak.longest,
      weeklyEntries: weekly,
      monthlyRecordedDays: monthly.days,
      monthString: monthly.monthString,
      totalEntries: total
    )
  }
}

// MARK: - 색상 / 스타일 공용
private let moodieTint = Color(red: 0.28, green: 0.48, blue: 0.58)
private let moodieOrange = Color.orange

private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

// MARK: - 1) Quick Entry 위젯 (Small)
struct QuickEntryWidget: Widget {
  let kind = "QuickEntryWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MoodieTimelineProvider()) { entry in
      QuickEntryWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("빠른 기록")
    .description("탭하면 바로 마음 날씨를 기록할 수 있어요.")
    .supportedFamilies([.systemSmall])
  }
}

struct QuickEntryWidgetView: View {
  let entry: MoodieTimelineEntry

  var body: some View {
    Link(destination: URL(string: "moodiesky://record")!) {
      VStack(spacing: 8) {
        Spacer()

        Image(systemName: "plus.circle.fill")
          .font(.system(size: 36, weight: .medium))
          .foregroundStyle(moodieTint)

        Text("마음 날씨 기록")
          .font(.system(.caption, design: .rounded, weight: .bold))
          .foregroundStyle(.primary)

        Text("탭해서 시작")
          .font(.caption2)
          .foregroundStyle(.secondary)

        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

// MARK: - 2) 주간 요약 위젯 (Medium)
struct WeeklySummaryWidget: Widget {
  let kind = "WeeklySummaryWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MoodieTimelineProvider()) { entry in
      WeeklySummaryWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("주간 마음 날씨")
    .description("최근 7일의 감정 기록을 한눈에 봐요.")
    .supportedFamilies([.systemMedium])
  }
}

struct WeeklySummaryWidgetView: View {
  let entry: MoodieTimelineEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("이번 주 마음 날씨")
          .font(.system(.subheadline, design: .rounded, weight: .bold))
        Spacer()
        if entry.currentStreak > 0 {
          HStack(spacing: 3) {
            Text("🔥")
              .font(.caption)
            Text("\(entry.currentStreak)일")
              .font(.system(.caption2, design: .rounded, weight: .bold))
              .foregroundStyle(moodieOrange)
          }
        }
      }

      HStack(spacing: 0) {
        ForEach(0..<7, id: \.self) { offset in
          let cal = Calendar.current
          let day = cal.date(byAdding: .day, value: offset - 6, to: entry.date) ?? entry.date
          let weekday = cal.component(.weekday, from: day)
          let isToday = cal.isDateInToday(day)
          let matchedEntry = entry.weeklyEntries.first {
            cal.isDate($0.date, inSameDayAs: day)
          }

          VStack(spacing: 4) {
            Text(weekdayLabels[weekday - 1])
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(isToday ? moodieTint : .secondary)

            Text("\(cal.component(.day, from: day))")
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(isToday ? .primary : .secondary)

            if let matched = matchedEntry {
              Text(matched.emoji)
                .font(.system(size: 20))
            } else {
              Circle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: 20, height: 20)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 6)
          .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(isToday ? moodieTint.opacity(0.08) : Color.clear)
          )
        }
      }
    }
    .padding(.horizontal, 4)
  }
}

// MARK: - 3) 다이어리 위젯 (Large)
struct DiaryWidget: Widget {
  let kind = "DiaryWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MoodieTimelineProvider()) { entry in
      DiaryWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("마음 다이어리")
    .description("이번 달 기록 현황을 캘린더로 확인해요.")
    .supportedFamilies([.systemLarge])
  }
}

struct DiaryWidgetView: View {
  let entry: MoodieTimelineEntry

  private var calendarDays: [Int?] {
    let cal = Calendar.current
    let today = entry.date
    guard let monthInterval = cal.dateInterval(of: .month, for: today) else { return [] }
    let firstDay = monthInterval.start
    let firstWeekday = cal.component(.weekday, from: firstDay) // 1=일
    let daysInMonth = cal.range(of: .day, in: .month, for: today)?.count ?? 30

    var days: [Int?] = Array(repeating: nil, count: firstWeekday - 1)
    for d in 1...daysInMonth {
      days.append(d)
    }
    return days
  }

  private var monthTitle: String {
    let cal = Calendar.current
    let year = cal.component(.year, from: entry.date)
    let month = cal.component(.month, from: entry.date)
    return "\(year)년 \(month)월"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // 헤더
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Moodie Sky")
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(moodieTint)
          Text(monthTitle)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          if entry.currentStreak > 0 {
            HStack(spacing: 2) {
              Text("🔥").font(.caption)
              Text("\(entry.currentStreak)일 연속")
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(moodieOrange)
            }
          }
          Text("\(entry.totalEntries)개 기록")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      // 요일 헤더
      HStack(spacing: 0) {
        ForEach(weekdayLabels, id: \.self) { label in
          Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(label == "일" ? .red.opacity(0.7) : label == "토" ? moodieTint : .secondary)
            .frame(maxWidth: .infinity)
        }
      }

      // 캘린더 그리드
      let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
      let todayDay = Calendar.current.component(.day, from: entry.date)

      LazyVGrid(columns: columns, spacing: 4) {
        ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, day in
          if let d = day {
            let hasRecord = entry.monthlyRecordedDays.contains(d)
            let isToday = d == todayDay

            ZStack {
              RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                  hasRecord
                    ? moodieTint.opacity(isToday ? 0.22 : 0.10)
                    : isToday ? moodieTint.opacity(0.06) : Color.clear
                )

              VStack(spacing: 1) {
                Text("\(d)")
                  .font(.system(size: 11, weight: isToday ? .black : hasRecord ? .bold : .regular))
                  .foregroundStyle(isToday ? moodieTint : hasRecord ? .primary : .secondary)

                if hasRecord {
                  Circle()
                    .fill(moodieTint)
                    .frame(width: 4, height: 4)
                }
              }
            }
            .frame(height: 32)
          } else {
            Color.clear.frame(height: 32)
          }
        }
      }

      Spacer(minLength: 0)

      // 하단 주간 요약 스트립
      if !entry.weeklyEntries.isEmpty {
        HStack(spacing: 4) {
          Text("이번 주")
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(.secondary)
          Spacer()
          ForEach(entry.weeklyEntries.suffix(7), id: \.date) { e in
            Text(e.emoji).font(.system(size: 14))
          }
        }
        .padding(.top, 4)
      }
    }
    .padding(.horizontal, 2)
  }
}

// MARK: - 4) Streak 위젯 (Small)
struct StreakWidget: Widget {
  let kind = "StreakWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: MoodieTimelineProvider()) { entry in
      StreakWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("연속 기록")
    .description("현재 streak과 최고 기록을 확인해요.")
    .supportedFamilies([.systemSmall])
  }
}

struct StreakWidgetView: View {
  let entry: MoodieTimelineEntry

  var body: some View {
    VStack(spacing: 6) {
      Spacer()

      Text(entry.currentStreak > 0 ? "🔥" : "💤")
        .font(.system(size: 38))

      Text("\(entry.currentStreak)")
        .font(.system(size: 36, weight: .black, design: .rounded))
        .foregroundStyle(entry.currentStreak > 0 ? moodieOrange : .secondary)

      Text(entry.currentStreak > 0 ? "일 연속" : "기록 없음")
        .font(.system(.caption, design: .rounded, weight: .bold))
        .foregroundStyle(.secondary)

      if entry.longestStreak > 0 {
        Text("최고 \(entry.longestStreak)일")
          .font(.system(.caption2, design: .rounded, weight: .semibold))
          .foregroundStyle(.tertiary)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Widget Bundle
@main
struct MoodieSkyWidgets: WidgetBundle {
  var body: some Widget {
    QuickEntryWidget()
    WeeklySummaryWidget()
    DiaryWidget()
    StreakWidget()
  }
}
