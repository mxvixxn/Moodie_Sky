import SwiftUI

extension ContentView {
  // MARK: - 다이어리 탭
  var calendarView: some View {
    NavigationStack {
    List {
      Section { calendarContent.listRowBackground(Color.clear).listRowInsets(EdgeInsets()) }
        .listRowSeparator(.hidden)
      Section {
        streakCard
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
      }
      Section { diarySearchControls.listRowBackground(Color.clear).listRowInsets(EdgeInsets()) }
        .listRowSeparator(.hidden)

      if isDiarySearchActive {
        Section("검색 결과") {
          let results = diarySearchResults
          if results.isEmpty {
            emptyStateView(
              icon: "magnifyingglass",
              title: "검색 결과가 없어요",
              message: "다른 단어나 날씨로 다시 찾아보세요."
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          } else {
            ForEach(results) { entry in
              diaryEntryListRow(entry, showsDate: true)
            }
          }
        }
      } else {
        Section("\(vm.formattedDate(vm.selectedDate))의 날씨") {
          let dayEntries = vm.entriesForDay(vm.selectedDate)
          if dayEntries.isEmpty {
            emptyStateView(
              icon: "moon.stars.fill",
              title: "이 날은 조용히 지나갔어요",
              message: "선택한 날짜에 남겨진 마음 날씨가 아직 없어요."
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          } else {
            ForEach(dayEntries) { entry in
              diaryEntryListRow(entry, isHighlighted: entry.id == vm.lastSavedEntryID)
            }
          }
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .padding(.horizontal)
    .navigationTitle("다이어리")
    .navigationBarTitleDisplayMode(.large)
    }
    .sheet(isPresented: $vm.shouldShowStreakBrokenAlert) {
      streakBrokenSheet
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
  }

  var isDiarySearchActive: Bool {
    !diarySearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || diarySearchWeather != "전체"
  }

  var diarySearchResults: [MoodEntry] {
    let query = diarySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    return vm.entries
      .filter { entry in
        let matchesWeather = diarySearchWeather == "전체" || entry.weather == diarySearchWeather
        guard matchesWeather else { return false }
        guard !query.isEmpty else { return true }
        return entry.note.localizedCaseInsensitiveContains(query)
          || entry.weather.localizedCaseInsensitiveContains(query)
          || entry.emoji.localizedCaseInsensitiveContains(query)
          || vm.formattedDate(entry.date).localizedCaseInsensitiveContains(query)
          || vm.formattedFullDate(entry.date).localizedCaseInsensitiveContains(query)
      }
      .sorted { $0.date > $1.date }
  }

  var diarySearchControls: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
        TextField("메모, 날씨, 날짜 검색", text: $diarySearchText)
          .font(.subheadline)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
        if !diarySearchText.isEmpty {
          Button { diarySearchText = "" } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 14))
              .foregroundStyle(.tertiary)
          }
          .buttonStyle(.plain)
        }
      }
      .moodieSecondaryControl()

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          diaryWeatherFilterButton(title: "전체", emoji: "", isSelected: diarySearchWeather == "전체") {
            diarySearchWeather = "전체"
          }
          ForEach(vm.weathers, id: \.0) { weather in
            diaryWeatherFilterButton(
              title: weather.0,
              emoji: weather.1,
              isSelected: diarySearchWeather == weather.0
            ) {
              diarySearchWeather = weather.0
            }
          }
        }
      }
    }
    .moodieCard(cornerRadius: vm.controlCornerRadius)
  }

  func diaryWeatherFilterButton(
    title: String,
    emoji: String,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 5) {
        if !emoji.isEmpty { Text(emoji) }
        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .moodieInsetSurface(cornerRadius: 999, tint: vm.moodieTint, isActive: isSelected)
      .foregroundStyle(isSelected ? vm.moodieTint : .primary)
      .clipShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  func diaryEntryListRow(
    _ entry: MoodEntry,
    isHighlighted: Bool = false,
    showsDate: Bool = false
  ) -> some View {
    entryRow(entry, isHighlighted: isHighlighted, showsDate: showsDate)
      .transition(.move(edge: .top).combined(with: .opacity))
      .onTapGesture { vm.selectedEntry = entry }
      .swipeActions(edge: .leading) {
        Button {
          vm.beginEditing(entry)
        } label: {
          Label("수정", systemImage: "pencil")
        }
        .tint(.blue)
      }
      .swipeActions(edge: .trailing) {
        Button(role: .destructive) {
          vm.requestDelete(entry)
        } label: {
          Label("삭제", systemImage: "trash")
        }
      }
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
  }

  var calendarContent: some View {
    VStack(spacing: 14) {
      HStack {
        Button(action: {
          vm.changeMonth(-1)
          vm.triggerHaptic(.soft)
        }) {
          Image(systemName: "chevron.left")
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 38, height: 38)
            .moodieInsetSurface(cornerRadius: 11, tint: vm.moodieTint)
        }.buttonStyle(.plain)

        Spacer()
        Text(vm.monthTitle(vm.displayedMonth))
          .font(.subheadline)
          .fontWeight(.bold)
          .id(vm.displayedMonth)
        Spacer()

        Button(action: {
          vm.changeMonth(1)
          vm.triggerHaptic(.soft)
        }) {
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 38, height: 38)
            .moodieInsetSurface(cornerRadius: 11, tint: vm.moodieTint)
        }.buttonStyle(.plain)
      }

      HStack {
        ForEach(vm.daysOfWeek, id: \.self) { day in
          Text(day)
            .font(.caption2).fontWeight(.bold)
            .foregroundStyle(vm.weekdayColor(day))
            .frame(maxWidth: .infinity)
        }
      }.padding(.horizontal, 4)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6)
      {
        ForEach(vm.calendarDays(for: vm.displayedMonth), id: \.id) { day in
          if let date = day.date {
            dayCell(date: date)
              .onTapGesture {
                vm.triggerHaptic(.light)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                  vm.selectedDate = date
                }
              }
          } else {
            Color.clear.frame(height: 80)
          }
        }
      }
    }
    .moodieCard(cornerRadius: vm.cardCornerRadius)
  }

  func dayCell(date: Date) -> some View {
    let dayEntries = vm.entriesForDay(date)
    let isToday = Calendar.current.isDateInToday(date)
    let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)

    return VStack(spacing: 0) {
      Text("\(Calendar.current.component(.day, from: date))")
        .font(.system(size: 12, weight: isSelected ? .black : .bold))
        .foregroundStyle(isToday ? vm.moodieTint : Color.primary)
        .padding(.top, 7)
      Spacer(minLength: 0)
      emojiAdaptiveLayout(entries: dayEntries)
      Spacer(minLength: 0)
    }
    .frame(height: 80).frame(maxWidth: .infinity)
    .moodieInsetSurface(
      cornerRadius: 12,
      tint: isToday ? vm.moodieTint : vm.accentColor(for: vm.selectedWeather),
      isActive: isSelected || isToday
    )
    .scaleEffect(isSelected ? 1.03 : 1)
    .shadow(
      color: isSelected ? vm.accentColor(for: vm.selectedWeather).opacity(0.12) : .clear,
      radius: 8, x: 0, y: 3
    )
    .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isSelected)
  }

  // MARK: - Streak 카드
  var streakCard: some View {
    HStack(spacing: 14) {
      // 불꽃 뱃지
      Text(vm.currentStreak > 0 ? "🔥" : "💤")
        .font(.system(size: 26))
        .frame(width: 46, height: 46)
        .moodieInsetSurface(
          cornerRadius: 23,
          tint: vm.currentStreak > 0 ? Color.orange : vm.moodieTint,
          isActive: vm.currentStreak > 0
        )

      VStack(alignment: .leading, spacing: 3) {
        if vm.currentStreak > 0 {
          Text("\(vm.currentStreak)일 연속 기록 중")
            .font(.subheadline).fontWeight(.bold)
          Text("역대 최고 \(vm.longestStreak)일 · 계속 이어가봐요 ✨")
            .font(.caption).foregroundStyle(.secondary)
        } else {
          Text("아직 기록이 없어요")
            .font(.subheadline).fontWeight(.semibold)
          Text("오늘부터 streak을 시작해봐요")
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      Spacer()
      if vm.currentStreak > 0 {
        VStack(spacing: 2) {
          Text("\(vm.currentStreak)")
            .font(.system(.title2, design: .rounded, weight: .black))
            .foregroundStyle(Color.orange)
          Text("일")
            .font(.caption2).fontWeight(.bold)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(14)
    .moodieInsetSurface(
      cornerRadius: vm.cardCornerRadius,
      tint: vm.currentStreak > 0 ? Color.orange : vm.moodieTint,
      isActive: vm.currentStreak > 0
    )
  }

  // MARK: - Streak 깨짐 시트
  var streakBrokenSheet: some View {
    ZStack {
      MoodieBackground(colors: vm.backgroundColors())
      VStack(spacing: 0) {
        Spacer()

        // 이모지
        Text("😔")
          .font(.system(size: 64))
          .padding(.bottom, 16)

        VStack(spacing: 8) {
          Text(vm.streakBrokenMessage)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .multilineTextAlignment(.center)
          Text("오늘부터 다시 도전해봐요.\n작은 한 줄이 또 다른 streak의 시작이에요.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)

        Spacer()

        Button {
          vm.shouldShowStreakBrokenAlert = false
        } label: {
          Text("오늘 기록하러 가기")
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(vm.moodieTint)
            .clipShape(RoundedRectangle(cornerRadius: vm.controlCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
    }
  }

  @ViewBuilder
  func emojiAdaptiveLayout(entries: [MoodEntry]) -> some View {
    let count = entries.count
    if count == 0 {
      Circle().fill(.white.opacity(0.2)).frame(width: 4, height: 4)
    } else if count == 1 {
      Text(entries[0].emoji).font(.system(size: 30))
    } else if count == 2 {
      HStack(spacing: 4) {
        Text(entries[1].emoji).font(.system(size: 14))
        Text(entries[0].emoji).font(.system(size: 14))
      }
    } else {
      VStack(spacing: 1) {
        HStack(spacing: 3) {
          Text(entries[2].emoji).font(.system(size: 11))
          Text(entries[1].emoji).font(.system(size: 11))
        }
        Text(entries[0].emoji).font(.system(size: 11))
      }
    }
  }
}
