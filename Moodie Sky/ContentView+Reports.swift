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
    }

    // MARK: - 리포트 카드
    var reportDashboard: some View {
      VStack(spacing: 12) {
        reportCard(vm.weeklyReport(for: Date()))
        reportCard(vm.monthlyReport(for: Date()))
      }
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
}
