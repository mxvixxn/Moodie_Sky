import SwiftUI

extension ContentView {
  // MARK: - 상세 보기 / 수정 시트
  func entryDetailView(_ entry: MoodEntry) -> some View {
    NavigationStack {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors(for: entry.weather))
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            Text(entry.emoji).font(.system(size: 72)).frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 8) {
              Text(entry.weather).font(.title).fontWeight(.bold)
              Text(vm.formattedFullDate(entry.date)).font(.subheadline).foregroundStyle(.secondary)
              Text(entry.note).font(.body).padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .moodieCard(cornerRadius: vm.cardCornerRadius)

            dayTimelineView(for: entry)
          }.padding()
        }
      }
      .navigationTitle("마음 날씨")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("수정") {
            vm.selectedEntry = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { vm.beginEditing(entry) }
          }
        }
      }
    }
  }

  func editEntryView(_ entry: MoodEntry) -> some View {
    NavigationStack {
      ZStack {
        MoodieBackground(colors: vm.backgroundColors(for: vm.editWeather))
        VStack(alignment: .leading, spacing: 20) {
          HStack(spacing: 12) {
            ForEach(vm.weathers, id: \.0) { weather in
              Button {
                vm.editWeather = weather.0
                vm.editEmoji = weather.1
                vm.triggerHaptic(.light)
              } label: {
                Text(weather.1).font(.system(size: 30))
                  .frame(maxWidth: .infinity).padding(.vertical, 14)
                  .moodieInsetSurface(
                    cornerRadius: vm.controlCornerRadius,
                    tint: vm.accentColor(for: weather.0),
                    isActive: vm.editWeather == weather.0
                  )
              }.buttonStyle(.plain)
            }
          }

          TextField("마음을 다시 적어보세요", text: $vm.editNote, axis: .vertical)
            .lineLimit(2...6)
            .padding()
            .moodieInsetSurface(
              cornerRadius: vm.cardCornerRadius,
              tint: vm.accentColor(for: vm.editWeather),
              isActive: !vm.editNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
          Spacer()
        }.padding()
      }
      .navigationTitle("기록 수정")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { Button("취소") { vm.entryToEdit = nil } }
        ToolbarItem(placement: .topBarTrailing) {
          Button("저장") { vm.updateEntry(entry) }
            .disabled(vm.editNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}
