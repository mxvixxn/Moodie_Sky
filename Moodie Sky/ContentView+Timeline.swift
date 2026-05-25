import SwiftUI

extension ContentView {
    func dayTimelineView(for selectedEntry: MoodEntry) -> some View {
      let dayEntries = vm.entriesForDay(selectedEntry.date)

      return VStack(alignment: .leading, spacing: 14) {
        VStack(alignment: .leading, spacing: 4) {
          Text("그날의 마음 흐름").font(.headline)
          Text("\(dayEntries.count)개의 기록이 시간 순서대로 이어져요")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, entry in
          let isSelected = entry.id == selectedEntry.id
          HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
              Text(entry.emoji)
                .font(.system(size: 21))
                .frame(width: 38, height: 38)
                .moodieInsetSurface(cornerRadius: 999, tint: vm.moodieTint, isActive: isSelected)
                .clipShape(Circle())

              if index < dayEntries.count - 1 {
                Rectangle()
                  .fill(vm.moodieTint.opacity(0.18))
                  .frame(width: 2, height: 36)
                  .clipShape(Capsule())
              }
            }

            VStack(alignment: .leading, spacing: 7) {
              HStack(spacing: 8) {
                Text(vm.timeText(entry.date))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(.secondary)
                Text(entry.weather)
                  .font(.caption2)
                  .fontWeight(.bold)
                  .foregroundStyle(vm.moodieTint)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .moodieInsetSurface(cornerRadius: 999, tint: vm.moodieTint, isActive: true)
                  .clipShape(Capsule())
                Spacer(minLength: 8)
                if isSelected {
                  Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(vm.moodieTint)
                }
              }

              Text(entry.note)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .moodieInsetSurface(cornerRadius: 16, tint: vm.moodieTint, isActive: isSelected)
          }
        }
      }
      .moodieCard(cornerRadius: vm.cardCornerRadius)
    }
}
