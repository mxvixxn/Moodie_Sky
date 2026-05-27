import SwiftUI

extension ContentView {
    // MARK: - 흐름 탭
    var flowView: some View {
      List {
        Section {
          VStack(alignment: .leading, spacing: 6) {
            Text("흐름")
              .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("쌓인 마음 날씨를 조용히 돌아봐요.")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
          .padding(.top, 12)
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        }

        Section {
          reportDashboard
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
        }
        .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }

    // MARK: - 리포트 카드
    var reportDashboard: some View {
      VStack(spacing: 12) {
        reportCard(vm.weeklyReport(for: Date()))
        reportCard(vm.monthlyReport(for: vm.displayedMonth))
      }
    }

    func reportCard(_ report: MoodReport) -> some View {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 10) {
          Text(report.emoji).font(.system(size: 34))
            .frame(width: 48, height: 48).background(.white.opacity(0.12)).clipShape(Circle())
          VStack(alignment: .leading, spacing: 4) {
            Text(report.title).font(.headline)
            Text(report.headline)
              .font(.subheadline)
              .fontWeight(.semibold)
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
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .moodieInsetSurface(cornerRadius: 12, tint: vm.moodieTint)

        Text(report.comparison)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(vm.moodieTint)
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .moodieInsetSurface(cornerRadius: 12, tint: vm.moodieTint, isActive: true)

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
