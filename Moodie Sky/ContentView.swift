    import CloudKit
    import SwiftData
    import SwiftUI
    import UniformTypeIdentifiers

    struct BackupShareItem: Identifiable {
      let url: URL
      var id: String { url.absoluteString }
    }

    struct ActivityView: UIViewControllerRepresentable {
      let activityItems: [Any]
      var onComplete: ((Bool) -> Void)? = nil

      func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
          onComplete?(completed)
        }
        return controller
      }

      func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }

    struct MoodieCardModifier: ViewModifier {
      let cornerRadius: CGFloat
      @Environment(\.colorScheme) private var colorScheme

      func body(content: Content) -> some View {
        content
          .padding()
          .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              .fill(.regularMaterial)
              .overlay {
                if colorScheme == .dark {
                  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                      LinearGradient(
                        colors: [
                          Color(red: 0.24, green: 0.36, blue: 0.38).opacity(0.16),
                          Color(red: 0.20, green: 0.18, blue: 0.28).opacity(0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    )
                }
              }
          }
          .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              .stroke(
                colorScheme == .dark ? Color.white.opacity(0.10) : Color.primary.opacity(0.055),
                lineWidth: 1
              )
          )
          .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.18) : Color.black.opacity(0.035),
            radius: colorScheme == .dark ? 18 : 10,
            x: 0,
            y: colorScheme == .dark ? 10 : 5
          )
      }
    }

    struct MoodieSecondaryControlModifier: ViewModifier {
      @Environment(\.colorScheme) private var colorScheme

      func body(content: Content) -> some View {
        content
          .padding(12)
          .background(
            colorScheme == .dark
              ? Color.white.opacity(0.055)
              : Color.primary.opacity(0.035)
          )
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
          )
      }
    }

    struct MoodieInsetSurfaceModifier: ViewModifier {
      let cornerRadius: CGFloat
      let tint: Color
      let isActive: Bool
      @Environment(\.colorScheme) private var colorScheme

      func body(content: Content) -> some View {
        content
          .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              .fill(colorScheme == .dark ? Color.white.opacity(0.052) : Color.primary.opacity(0.04))
              .overlay {
                if colorScheme == .dark {
                  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(isActive ? 0.16 : 0.045))
                } else if isActive {
                  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(0.12))
                }
              }
          }
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              .stroke(
                isActive
                  ? tint.opacity(colorScheme == .dark ? 0.42 : 0.36)
                  : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.primary.opacity(0.045)),
                lineWidth: isActive ? 1.3 : 1
              )
          )
      }
    }

    extension View {
      func moodieCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(MoodieCardModifier(cornerRadius: cornerRadius))
      }

      func moodieSecondaryControl() -> some View {
        modifier(MoodieSecondaryControlModifier())
      }

      func moodieInsetSurface(
        cornerRadius: CGFloat = 14,
        tint: Color = Color(red: 0.28, green: 0.48, blue: 0.58),
        isActive: Bool = false
      ) -> some View {
        modifier(MoodieInsetSurfaceModifier(cornerRadius: cornerRadius, tint: tint, isActive: isActive))
      }
    }

    struct MoodieIconBadge: View {
      let systemName: String
      let color: Color
      @Environment(\.colorScheme) private var colorScheme

      var body: some View {
        Image(systemName: systemName)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(color)
          .frame(width: 34, height: 34)
          .background(color.opacity(colorScheme == .dark ? 0.18 : 0.11))
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 1)
          )
      }
    }

    enum DataDeleteScope {
      case today
      case month
      case all
    }

    enum SettingsRoute: Hashable {
      case general
      case notifications
      case security
      case data
    }

    // MARK: - 데이터 모델
    @Model
    final class MoodEntry: Identifiable, Codable {
      @Attribute(.unique) var id: UUID
      var date: Date
      var weather: String
      var emoji: String
      var note: String
      var intensity: Int = 3
      var updatedAt: Date
      var needsSync: Bool
      var cloudRecordName: String?

      init(
        id: UUID = UUID(),
        date: Date,
        weather: String,
        emoji: String,
        note: String,
        intensity: Int = 3,
        updatedAt: Date = Date(),
        needsSync: Bool = true,
        cloudRecordName: String? = nil
      ) {
        self.id = id
        self.date = date
        self.weather = weather
        self.emoji = emoji
        self.note = note
        self.intensity = min(max(intensity, 1), 5)
        self.updatedAt = updatedAt
        self.needsSync = needsSync
        self.cloudRecordName = cloudRecordName
      }

      enum CodingKeys: String, CodingKey {
        case id, date, weather, emoji, note, intensity, updatedAt, needsSync, cloudRecordName
      }

      required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedDate = try container.decode(Date.self, forKey: .date)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = decodedDate
        self.weather = try container.decode(String.self, forKey: .weather)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.note = try container.decode(String.self, forKey: .note)
        let decodedIntensity = try container.decodeIfPresent(Int.self, forKey: .intensity) ?? 3
        self.intensity = min(max(decodedIntensity, 1), 5)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? decodedDate
        self.needsSync = try container.decodeIfPresent(Bool.self, forKey: .needsSync) ?? true
        self.cloudRecordName = try container.decodeIfPresent(String.self, forKey: .cloudRecordName)
      }

      func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(weather, forKey: .weather)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(note, forKey: .note)
        try container.encode(intensity, forKey: .intensity)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(needsSync, forKey: .needsSync)
        try container.encodeIfPresent(cloudRecordName, forKey: .cloudRecordName)
      }
    }

    struct CloudSyncResult {
      var entries: [MoodEntry]
      var pendingDeleteIDs: [UUID]
    }

    enum CloudSyncStatus: Equatable {
      case idle, syncing
      case synced(Date)
      case offline
      case failed(String)

      var message: String {
        switch self {
        case .idle: return "iCloud 동기화 대기 중"
        case .syncing: return "iCloud 동기화 중"
        case .synced(let date):
          let f = DateFormatter()
          f.locale = Locale(identifier: "ko_KR")
          f.timeStyle = .short
          return "마지막 동기화: \(f.string(from: date))"
        case .offline: return "오프라인 상태예요. 다음 실행 때 다시 동기화해요."
        case .failed(let msg): return msg
        }
      }
    }

    struct CalendarDay: Identifiable {
      let id: String
      let date: Date?
    }

    // MARK: - CloudSyncManager
    final class CloudSyncManager {
      static let shared = CloudSyncManager()
      private let database = CKContainer(identifier: "iCloud.com.mxvixxn.Moodie-Sky")
        .privateCloudDatabase
      private let recordType = "MoodEntry"
      private init() {}

      func sync(entries: [MoodEntry], pendingDeleteIDs: [UUID]) async throws -> CloudSyncResult {
        var remainingDeleteIDs: [UUID] = []

        for id in pendingDeleteIDs {
          do {
            _ = try await database.deleteRecord(withID: CKRecord.ID(recordName: id.uuidString))
          } catch let error as CKError where error.code == .unknownItem {
            continue
          } catch {
            remainingDeleteIDs.append(id)
          }
        }

        var localByID = Dictionary(
          uniqueKeysWithValues: entries.map { ($0.id, $0.normalizedForSync()) })

        for entry in localByID.values where entry.needsSync {
          let recordID = CKRecord.ID(recordName: entry.id.uuidString)
          let record: CKRecord
          do {
            record = try await database.record(for: recordID)
          } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: recordType, recordID: recordID)
          }
          apply(entry, to: record)
          let savedRecord = try await database.save(record)
          if let savedEntry = localByID[entry.id] {
            savedEntry.needsSync = false
            savedEntry.cloudRecordName = savedRecord.recordID.recordName
            localByID[entry.id] = savedEntry
          }
        }

        let remoteEntries = try await fetchRemoteEntries()
        for remoteEntry in remoteEntries {
          if let localEntry = localByID[remoteEntry.id] {
            if remoteEntry.updatedAt > localEntry.updatedAt {
              localByID[remoteEntry.id] = remoteEntry
            }
          } else if !remainingDeleteIDs.contains(remoteEntry.id) {
            localByID[remoteEntry.id] = remoteEntry
          }
        }

        let mergedEntries = localByID.values.sorted { $0.date > $1.date }
        return CloudSyncResult(entries: mergedEntries, pendingDeleteIDs: remainingDeleteIDs)
      }

      private func fetchRemoteEntries() async throws -> [MoodEntry] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        return result.matchResults.compactMap { _, recordResult in
          guard case .success(let record) = recordResult else { return nil }
          return MoodEntry(record: record)
        }
      }

      private func apply(_ entry: MoodEntry, to record: CKRecord) {
        record["entryID"] = entry.id.uuidString as CKRecordValue
        record["date"] = entry.date as CKRecordValue
        record["weather"] = entry.weather as CKRecordValue
        record["emoji"] = entry.emoji as CKRecordValue
        record["note"] = entry.note as CKRecordValue
        record["intensity"] = entry.intensity as CKRecordValue
        record["updatedAt"] = entry.updatedAt as CKRecordValue
      }
    }

    extension MoodEntry {
      convenience init(record: CKRecord) {
        let fallbackID = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let entryID =
          UUID(uuidString: record["entryID"] as? String ?? record.recordID.recordName) ?? fallbackID
        let recordDate = record["date"] as? Date ?? Date()
        self.init(
          id: entryID,
          date: recordDate,
          weather: record["weather"] as? String ?? "구름",
          emoji: record["emoji"] as? String ?? "☁️",
          note: record["note"] as? String ?? "",
          intensity: record["intensity"] as? Int ?? 3,
          updatedAt: record["updatedAt"] as? Date ?? recordDate,
          needsSync: false,
          cloudRecordName: record.recordID.recordName
        )
      }

      func normalizedForSync() -> MoodEntry {
        MoodEntry(
          id: id,
          date: date,
          weather: weather,
          emoji: emoji,
          note: note,
          intensity: intensity,
          updatedAt: updatedAt,
          needsSync: needsSync,
          cloudRecordName: cloudRecordName ?? id.uuidString
        )
      }
    }

    // MARK: - ContentView
    struct ContentView: View {
      @Environment(\.modelContext) var modelContext
      @Environment(\.scenePhase) var scenePhase
      @StateObject var vm = MoodViewModel()

      @State var selection = 0
      @State var diarySearchText = ""
      @State var diarySearchWeather = "전체"
      @State var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenMoodieTutorial")
      @State var onboardingPage = 0
      @State var showLaunchSplash = true
      @State var showPasscodeSetup = false
      @State var showBackupAuth = false
      @State var showBackupEncryptionSetup = false
      @State var showBackupImportAuth = false
      @State var showEncryptedBackupImportPassword = false
      @State var showBackupFormatOptions = false
      @State var showBackupImport = false
      @State var showDeleteAuth = false
      @State var deleteAuthPasscode = ""
      @State var pendingDeleteScope: DataDeleteScope = .all
      @State var isPrivacyShieldVisible = false
      @State var backupAuthPasscode = ""
      @State var backupEncryptionPassword = ""
      @State var backupEncryptionConfirmation = ""
      @State var backupImportAuthPasscode = ""
      @State var encryptedBackupImportPassword = ""
      @State var backupExportFormat: BackupExportFormat = .csv
      @State var backupShareItem: BackupShareItem?
      @State var pendingBackupImportURL: URL?
      @State var pendingBackupImportPassword: String?
      @State var backupImportPreview: BackupImportPreview?
      @State var pendingDeleteAfterBackup = false
      @State var passcodeSetupDigitCount = 4
      @State var newPasscode = ""
      @State var confirmPasscode = ""
      @State var showForgotPasscodeResetAlert = false
      @State var showRecoveryKeyReset = false
      @State var recoveryKeyInput = ""
      @State var recoveryNewPasscode = ""
      @State var recoveryConfirmPasscode = ""
      @State var recoveryKeyToShow = ""
      @State var showRecoveryKeyNotice = false
      @State var showRecoveryKeyConfirmation = false
      @State var recoveryKeyConfirmationInput = ""
      @State var backupFormatSelectionInProgress = false
      @State var didRunInitialAppear = false

      var body: some View {
        rootTabView
        .animation(.easeInOut(duration: 0.22), value: selection)
        .onChange(of: selection) { _, _ in vm.triggerHaptic(.medium) }
        .onAppear {
          guard !didRunInitialAppear else { return }
          didRunInitialAppear = true
          vm.configure(modelContext: modelContext)
          selection = vm.preferredStartTab.rawValue
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            vm.syncWithICloud()
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.28)) { showLaunchSplash = false }
          }
        }
      }

      @ViewBuilder
      var rootTabView: some View {
        if #available(iOS 18.0, *) {
          tabs
            .tabBarMinimizeBehavior(.onScrollDown)
        } else {
          tabs
        }
      }

      var tabs: some View {
        TabView(selection: $selection) {
          ZStack {
            MoodieBackground(colors: vm.backgroundColors())
            recordView
          }
          .tabItem { Label("오늘", systemImage: "cloud") }.tag(0)

          ZStack {
            MoodieBackground(colors: vm.backgroundColors())
            flowView
          }
          .tabItem { Label("흐름", systemImage: "wind") }.tag(2)

          ZStack {
            MoodieBackground(colors: vm.backgroundColors())
            calendarView
          }
          .tabItem { Label("다이어리", systemImage: "book.pages") }.tag(1)

          ZStack {
            MoodieBackground(colors: vm.backgroundColors())
            settingsView
          }
          .tabItem { Label("관리", systemImage: "line.3.horizontal") }.tag(3)
        }
        .alert("기록을 삭제할까요?", isPresented: $vm.showDeleteAlert) {
          Button("삭제", role: .destructive) { vm.deleteConfirmed() }
          Button("취소", role: .cancel) {}
        }
        .alert("모든 기록을 지울까요?", isPresented: $vm.showAllDeleteAlert) {
          Button("백업 먼저") {
            pendingDeleteAfterBackup = true
            requestBackupExport()
          }
          Button("모두 삭제", role: .destructive) { vm.deleteAllEntries() }
          Button("취소", role: .cancel) { pendingDeleteAfterBackup = false }
        } message: {
          Text("삭제 전 백업을 만들어두면 실수로 지운 기록을 복원할 수 있어요.")
        }
        .sheet(item: $vm.selectedEntry) { entry in entryDetailView(entry) }
        .sheet(item: $vm.entryToEdit) { entry in editEntryView(entry) }
        .sheet(isPresented: $showPasscodeSetup) { passcodeSetupView }
        .sheet(isPresented: $showRecoveryKeyReset) { recoveryKeyResetView }
        .sheet(isPresented: $showRecoveryKeyConfirmation) { recoveryKeyConfirmationView }
        .sheet(isPresented: $showBackupFormatOptions, onDismiss: {
          if !backupFormatSelectionInProgress {
            pendingDeleteAfterBackup = false
          }
          backupFormatSelectionInProgress = false
        }) {
          backupFormatOptionsView
            .presentationDetents([.height(310)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBackupAuth) { backupAuthView }
        .sheet(isPresented: $showBackupEncryptionSetup) { backupEncryptionSetupView }
        .sheet(isPresented: $showBackupImportAuth) { backupImportAuthView }
        .sheet(isPresented: $showEncryptedBackupImportPassword) { encryptedBackupImportPasswordView }
        .sheet(item: $backupImportPreview) { preview in backupImportPreviewView(preview) }
        .sheet(item: $backupShareItem) { item in
          ActivityView(activityItems: [item.url]) { completed in
            vm.cleanupBackupExportFile(at: item.url)
            backupShareItem = nil
            if pendingDeleteAfterBackup {
              pendingDeleteAfterBackup = false
              if completed {
                vm.showAllDeleteAlert = true
              }
            }
          }
        }
        .alert("복구키를 저장해주세요", isPresented: $showRecoveryKeyNotice) {
          Button("확인") {
            recoveryKeyConfirmationInput = ""
            showRecoveryKeyConfirmation = true
          }
        } message: {
          Text("아래 키를 안전한 곳에 저장해주세요. 다음 화면에서 같은 키를 다시 입력해야 앱 암호와 복구키가 설정됩니다.\n\n\(recoveryKeyToShow)")
        }
        .fileImporter(
          isPresented: $showBackupImport,
          allowedContentTypes: [.json, .commaSeparatedText, .plainText, .data],
          allowsMultipleSelection: false
        ) { result in
          if case .success(let urls) = result, let url = urls.first {
            requestBackupImport(from: url)
          }
        }
        .sheet(isPresented: $showDeleteAuth) { deleteAuthView }
        .preferredColorScheme(vm.appTheme.colorScheme)
        .fullScreenCover(isPresented: $showOnboarding) { onboardingView }
        .overlay {
          if showLaunchSplash {
            launchSplashView.transition(.opacity)
          }
        }
        .overlay {
          if vm.shouldShowLockScreen && !showLaunchSplash {
            lockScreenView.transition(.opacity)
          }
        }
        .overlay {
          if isPrivacyShieldVisible {
            privacyShieldView
              .transition(.opacity)
              .zIndex(10)
          }
        }
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .background {
            isPrivacyShieldVisible = vm.obscuresAppSwitcher
            vm.noteAppDidEnterBackground()
          } else if newPhase == .inactive {
            isPrivacyShieldVisible = vm.obscuresAppSwitcher
          } else if newPhase == .active {
            isPrivacyShieldVisible = false
            vm.handleAppDidBecomeActive()
          }
        }
        .onTapGesture { vm.hideKeyboard() }
      }
    }

    // MARK: - MoodieBackground
    struct MoodieBackground: View {
      let colors: [Color]
      @Environment(\.colorScheme) private var colorScheme

      var body: some View {
        ZStack {
          if colorScheme == .dark {
            LinearGradient(
              colors: [
                Color(red: 0.07, green: 0.10, blue: 0.12),
                Color(red: 0.11, green: 0.16, blue: 0.18),
                Color(red: 0.13, green: 0.11, blue: 0.17),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          } else {
            Color(.systemGroupedBackground)
          }

          LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .opacity(colorScheme == .dark ? 0.48 : 0.86)

          if colorScheme == .dark {
            LinearGradient(
              colors: [
                Color.white.opacity(0.045),
                Color.clear,
                Color(red: 0.34, green: 0.46, blue: 0.50).opacity(0.10),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
            .blendMode(.screen)
          }
        }.ignoresSafeArea()
      }
    }

    #Preview("Moodie Sky") {
      ContentView()
        .modelContainer(MoodiePreviewContainer.container)
    }

    #Preview("Moodie Sky - Dark") {
      ContentView()
        .modelContainer(MoodiePreviewContainer.container)
        .preferredColorScheme(.dark)
    }
