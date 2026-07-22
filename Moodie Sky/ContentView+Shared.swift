import SwiftUI

extension ContentView {
  func emptyStateView(icon: String, title: String, message: String) -> some View {
    VStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 24, weight: .semibold))
        .foregroundStyle(vm.moodieTint)
        .frame(width: 50, height: 50)
        .moodieInsetSurface(cornerRadius: 25, tint: vm.moodieTint, isActive: true)

      VStack(spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .multilineTextAlignment(.center)
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity)
    .moodieCard(cornerRadius: vm.cardCornerRadius)
  }

  // MARK: - 공통 컴포넌트
  var todaySummaryCard: some View {
    HStack(spacing: 12) {
      Text(vm.todaySummaryEmoji)
        .font(.system(size: 30))
        .frame(width: 50, height: 50)
        .moodieInsetSurface(
          cornerRadius: 25,
          tint: vm.accentColor(for: vm.selectedWeather),
          isActive: true
        )

      VStack(alignment: .leading, spacing: 4) {
        Text(vm.todaySummaryTitle)
          .font(.subheadline)
          .fontWeight(.semibold)
          .fixedSize(horizontal: false, vertical: true)
        Text(vm.todaySummaryDetail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 6)
    }
    .padding(13)
    .moodieInsetSurface(
      cornerRadius: vm.cardCornerRadius,
      tint: vm.accentColor(for: vm.selectedWeather),
      isActive: true
    )
  }

  var weatherSelector: some View {
    HStack(spacing: 6) {
      ForEach(vm.weathers, id: \.0) { w in
        let isSelected = vm.selectedWeather == w.0
        Button {
          vm.selectedWeather = w.0
          vm.selectedEmoji = w.1
          vm.triggerHaptic(.light)
        } label: {
          VStack(spacing: 3) {
            Text(w.1).font(.system(size: isSelected ? 28 : 24))
              .frame(maxWidth: .infinity)
            Text(w.0).font(.caption2).fontWeight(.medium)
              .foregroundStyle(isSelected ? .primary : .tertiary)
          }
          .frame(maxWidth: .infinity).padding(.vertical, isSelected ? 11 : 9)
          .moodieInsetSurface(
            cornerRadius: 12,
            tint: vm.accentColor(for: w.0),
            isActive: isSelected
          )
          .scaleEffect(isSelected ? 1.02 : 1)
          .shadow(
            color: isSelected ? vm.accentColor(for: w.0).opacity(0.08) : .clear, radius: 5, x: 0,
            y: 2
          )
          .animation(.spring(response: 0.26, dampingFraction: 0.76), value: isSelected)
        }.buttonStyle(.plain)
      }
    }
  }

  var saveConfirmationView: some View {
    Label(vm.saveConfirmationText, systemImage: "checkmark.circle.fill")
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(vm.moodieTint)
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .moodieInsetSurface(cornerRadius: 14, tint: vm.moodieTint, isActive: true)
  }

  var saveButtonView: some View {
    let canSubmit = vm.canSubmitEntry

    return Button(action: vm.saveEntry) {
      Text(vm.canSaveToday ? "저장하기" : "오늘은 충분히 기록했어요")
        .font(.subheadline)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .contentShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
      .background(
        canSubmit
          ? vm.accentColor(for: vm.selectedWeather) : Color.secondary.opacity(0.18)
      )
      .foregroundColor(canSubmit ? .white : .secondary)
      .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(!canSubmit)
  }

  func entryRow(_ entry: MoodEntry, isHighlighted: Bool = false, showsDate: Bool = false) -> some View {
    HStack(spacing: 12) {
      Text(entry.emoji).font(.title2).frame(width: 42, height: 42)
        .moodieInsetSurface(
          cornerRadius: 21,
          tint: vm.accentColor(for: entry.weather),
          isActive: isHighlighted
        )
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(showsDate ? vm.formattedFullDate(entry.date) : vm.timeText(entry.date))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
          Text(entry.weather)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(vm.accentColor(for: entry.weather))
        }
        Text(entry.note)
          .font(.subheadline)
          .foregroundStyle(.primary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 4)
    }
    .padding(13)
    .moodieInsetSurface(
      cornerRadius: vm.cardCornerRadius,
      tint: vm.accentColor(for: entry.weather),
      isActive: isHighlighted
    )
    .scaleEffect(isHighlighted ? 1.01 : 1)
    .animation(.spring(response: 0.26, dampingFraction: 0.82), value: isHighlighted)
  }
}
