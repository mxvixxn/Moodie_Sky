import SwiftUI

extension ContentView {
    // MARK: - 흐름 탭
    var flowView: some View {
      NavigationStack {
        List {
          Section {
            reportDashboard
              .listRowBackground(Color.clear)
              .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
          }
          .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("흐름")
        .navigationBarTitleDisplayMode(.large)
      }
      .task {
        await vm.refreshMindfulMinutes()
      }
    }

    // MARK: - 리포트 카드
    var reportDashboard: some View {
      VStack(spacing: 12) {
        if vm.isHealthKitMindfulnessEnabled {
          mindfulnessCard
        }
        reportCard(vm.weeklyReport(for: Date()))
        reportCard(vm.monthlyReport(for: vm.displayedMonth))
      }
    }

    // MARK: - 마음챙김 연동 카드 (Fitie)
    var mindfulnessCard: some View {
      let insight = vm.mindfulnessCorrelationInsight(
        mindfulDays: vm.weeklyMindfulDays, entries: vm.entriesForWeek(Date()))

      return VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          Text("🧘").font(.system(size: 32))
            .frame(width: 46, height: 46)
            .background(.white.opacity(0.10))
            .clipShape(Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text("이번 주 마음챙김").font(.subheadline).fontWeight(.bold)
            Text("Fitie와 함께 보낸 시간이에요")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack(spacing: 8) {
          reportStat(title: "마음챙김 분", value: "\(Int(vm.weeklyMindfulMinutes.rounded()))")
          reportStat(title: "함께한 날", value: "\(vm.weeklyMindfulDays.count)")
        }

        if let insight {
          Text(insight)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .moodieInsetSurface(cornerRadius: 11, tint: vm.moodieTint)
        }
      }
      .moodieCard(cornerRadius: vm.cardCornerRadius)
    }

    func reportCard(_ report: MoodReport) -> some View {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          Text(report.emoji).font(.system(size: 32))
            .frame(width: 46, height: 46)
            .background(.white.opacity(0.10))
            .clipShape(Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text(report.title)
              .font(.subheadline)
              .fontWeight(.bold)
            Text(report.headline)
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
              .lineLimit(2)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        Text(report.detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        Text(report.insight)
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 11)
          .padding(.vertical, 9)
          .frame(maxWidth: .infinity, alignment: .leading)
          .moodieInsetSurface(cornerRadius: 11, tint: vm.moodieTint)

        Text(report.comparison)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(vm.moodieTint)
          .padding(.horizontal, 11)
          .padding(.vertical, 9)
          .frame(maxWidth: .infinity, alignment: .leading)
          .moodieInsetSurface(cornerRadius: 11, tint: vm.moodieTint, isActive: true)

        HStack(spacing: 8) {
          reportStat(title: "기록", value: "\(report.entriesCount)")
          reportStat(title: "남긴 날", value: "\(report.activeDaysCount)")
        }
      }
      .moodieCard(cornerRadius: vm.cardCornerRadius)
    }

    func reportStat(title: String, value: String) -> some View {
      VStack(alignment: .leading, spacing: 2) {
        Text(value).font(.headline).fontWeight(.bold)
        Text(title).font(.caption).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .moodieInsetSurface(cornerRadius: 14, tint: Color(red: 0.28, green: 0.48, blue: 0.58))
    }

    // MARK: - 월간 요약 카드
    var monthlySummaryCard: some View {
      let monthEntries = vm.entriesForMonth(vm.displayedMonth)
      let summary = vm.monthlySummary(for: vm.displayedMonth)

      return VStack(alignment: .leading, spacing: 10) {
        Text("이번 달 마음 하늘").font(.headline)
        HStack(spacing: 12) {
          Text(summary.emoji).font(.system(size: 34))
            .frame(width: 54, height: 54).background(.white.opacity(0.14)).clipShape(Circle())
          VStack(alignment: .leading, spacing: 4) {
            Text(summary.title).fontWeight(.bold)
            Text("\(monthEntries.count)번의 마음 날씨를 남겼어요").font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
        }
      }
      .moodieCard(cornerRadius: vm.cardCornerRadius)
    }
}
