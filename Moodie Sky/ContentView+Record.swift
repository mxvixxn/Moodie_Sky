import SwiftUI

extension ContentView {
    var activeTabHeader: some View {
      HStack(spacing: 8) {
        Image(systemName: activeTabHeaderIcon)
        .font(.caption)
        .foregroundStyle(vm.accentColor(for: vm.selectedWeather))
        Text(activeTabHeaderTitle)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.top, 4)
      .id(selection)
      .transition(.opacity.combined(with: .move(edge: .top)))
    }

    var activeTabHeaderIcon: String {
      switch selection {
      case 0: return "cloud"
      case 1: return "book.pages"
      case 2: return "wind"
      default: return "line.3.horizontal"
      }
    }

    var activeTabHeaderTitle: String {
      switch selection {
      case 0: return "오늘"
      case 1: return "다이어리"
      case 2: return "흐름"
      default: return "관리"
      }
    }

    // MARK: - 기록 탭

    var recordView: some View {
      List {
        Section {
          recordInputCard
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 10, trailing: 16))
        }

        Section {
          HStack(alignment: .firstTextBaseline) {
            Text("오늘의 날씨").font(.subheadline).fontWeight(.semibold)
            Spacer()
            Text("\(vm.todayEntriesCount)개")
              .font(.caption2).fontWeight(.bold).foregroundStyle(.tertiary)
          }
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

          let todayEntries = vm.todayEntries
          if todayEntries.isEmpty {
            emptyStateView(
              icon: "sparkles",
              title: "오늘 마음 하늘을 비워뒀어요",
              message: "날씨 하나와 한 줄이면 충분해요. 지금 떠오르는 마음부터 가볍게 남겨봐요."
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
          } else {
            ForEach(todayEntries) { entry in
              entryRow(entry, isHighlighted: entry.id == vm.lastSavedEntryID)
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
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button(role: .destructive) {
                    vm.requestDelete(entry)
                  } label: {
                    Label("삭제", systemImage: "trash")
                  }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
          }
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
    }

    var recordInputCard: some View {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 5) {
          Text("Moodie Sky")
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(vm.moodieTint)
          Text(vm.formattedHeaderDate(Date()))
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(.primary)
          Text(vm.todayPrompt)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 6)

        todaySummaryCard
        weatherSelector

        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("한 줄 메모").font(.subheadline).fontWeight(.semibold)
            Spacer()
            Text("\(vm.todayEntriesCount)/3")
              .font(.caption2).fontWeight(.bold).foregroundStyle(.tertiary)
          }
          TextField(vm.notePrompt, text: $vm.note, axis: .vertical)
            .lineLimit(1...5)
            .padding(.vertical, 13).padding(.horizontal, 15)
            .moodieInsetSurface(
              cornerRadius: vm.controlCornerRadius,
              tint: vm.accentColor(for: vm.selectedWeather),
              isActive: !vm.trimmedNote.isEmpty
            )
            .frame(minHeight: 48)
        }
        saveButtonView
        if vm.showSaveConfirmation {
          saveConfirmationView
            .transition(.move(edge: .top).combined(with: .opacity))
        }
      }
    }
}
