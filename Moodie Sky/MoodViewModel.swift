import CloudKit
import Combine
import CryptoKit
import LocalAuthentication
import Security
import SwiftData
import SwiftUI
@preconcurrency import UserNotifications

// MARK: - MoodViewModel
// ContentView에서 모든 로직을 분리한 ViewModel입니다.
// @MainActor: UI 업데이트가 항상 메인 스레드에서 일어나도록 보장합니다.

struct MoodReport {
  let title: String
  let emoji: String
  let headline: String
  let detail: String
  let comparison: String
  let insight: String
  let entriesCount: Int
  let activeDaysCount: Int
}

struct MoodBackupPayload: Codable {
  let appName: String
  let schemaVersion: Int
  let exportedAt: Date
  let entries: [MoodEntry]
}


enum AppStartTab: Int, CaseIterable, Identifiable {
  case record = 0
  case diary = 1
  case settings = 2

  var id: Int { rawValue }
  var label: String {
    switch self {
    case .record: return "기록"
    case .diary: return "다이어리"
    case .settings: return "설정"
    }
  }
}

enum MoodDateDisplayStyle: String, CaseIterable, Identifiable {
  case korean
  case numeric
  case compact

  var id: String { rawValue }
  var label: String {
    switch self {
    case .korean: return "한국어"
    case .numeric: return "숫자"
    case .compact: return "짧게"
    }
  }
}

enum MoodAppTheme: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String { rawValue }
  var label: String {
    switch self {
    case .system: return "시스템"
    case .light: return "밝게"
    case .dark: return "어둡게"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

enum ReminderToneStyle: String, CaseIterable, Identifiable {
  case gentle
  case short
  case random

  var id: String { rawValue }
  var label: String {
    switch self {
    case .gentle: return "다정하게"
    case .short: return "짧게"
    case .random: return "랜덤"
    }
  }
}

enum BackupExportFormat: String, CaseIterable, Identifiable {
  case csv
  case json
  case encryptedJSON

  var id: Self { self }
  var label: String {
    switch self {
    case .csv: return "CSV"
    case .json: return "JSON"
    case .encryptedJSON: return "암호화 백업"
    }
  }
  var fileExtension: String {
    switch self {
    case .csv: return "csv"
    case .json: return "json"
    case .encryptedJSON: return "moodieskybackup"
    }
  }
}

struct EncryptedBackupPayload: Codable {
  let appName: String
  let schemaVersion: Int
  let algorithm: String
  let salt: Data
  let sealedData: Data
  let exportedAt: Date
}

struct BackupImportPreview: Identifiable {
  let id = UUID()
  let totalEntries: Int
  let newEntries: Int
  let updatedEntries: Int
  let unchangedEntries: Int
  let earliestDate: Date?
  let latestDate: Date?
}

enum BackupImportError: LocalizedError {
  case fileTooLarge
  case unsupportedFormat
  case invalidEncoding
  case missingRequiredFields
  case tooManyEntries
  case dateOutOfRange
  case passwordRequired
  case weakBackupPassword
  case invalidBackupPassword

  var errorDescription: String? {
    switch self {
    case .fileTooLarge: return "백업 파일이 너무 커요. 5MB 이하 파일만 가져올 수 있어요."
    case .unsupportedFormat: return "CSV, JSON 또는 암호화 백업 파일만 가져올 수 있어요."
    case .invalidEncoding: return "파일 인코딩을 읽을 수 없어요."
    case .missingRequiredFields: return "백업 파일에 필요한 항목이 부족해요."
    case .tooManyEntries: return "한 번에 가져올 수 있는 기록 수를 초과했어요."
    case .dateOutOfRange: return "백업 파일에 허용 범위를 벗어난 날짜가 있어요."
    case .passwordRequired: return "암호화 백업 암호가 필요해요."
    case .weakBackupPassword: return "백업 암호는 8자 이상으로 설정해주세요."
    case .invalidBackupPassword: return "백업 암호가 맞지 않거나 파일이 손상됐어요."
    }
  }
}

@MainActor
final class MoodViewModel: ObservableObject {

  private static func emoji(for weather: String) -> String {
    switch weather {
    case "맑음": return "☀️"
    case "구름": return "☁️"
    case "비": return "🌧️"
    case "폭풍": return "⛈️"
    case "무지개": return "🌈"
    default: return "☀️"
    }
  }

  // MARK: - Published 상태 (UI가 구독)
  @Published var entries: [MoodEntry] = []
  @Published var syncStatus: CloudSyncStatus = .idle
  @Published var selectedWeather = "맑음"
  @Published var selectedEmoji = "☀️"
  @Published var note = ""
  @Published var todayPrompt = ""
  @Published var notePrompt = ""
  @Published var selectedEntry: MoodEntry? = nil
  @Published var entryToEdit: MoodEntry? = nil
  @Published var editWeather = "맑음"
  @Published var editEmoji = "☀️"
  @Published var editNote = ""
  @Published var entryToDelete: MoodEntry? = nil
  @Published var showDeleteAlert = false
  @Published var showAllDeleteAlert = false
  @Published var displayedMonth = Date()
  @Published var selectedDate = Date()
  @Published var isReminderEnabled: Bool
  @Published var reminderTime: Date
  @Published var selectedReminderWeekdays: Set<Int>
  @Published var reminderToneStyle: ReminderToneStyle
  @Published var skipsReminderAfterTodayEntry: Bool
  @Published var quietHoursEnabled: Bool
  @Published var quietHoursStart: Date
  @Published var quietHoursEnd: Date
  @Published var backupReminderEnabled: Bool
  @Published var backupReminderDays: Int
  @Published var lastBackupExportedAt: Date?
  @Published var preferredStartTab: AppStartTab
  @Published var dateDisplayStyle: MoodDateDisplayStyle
  @Published var appTheme: MoodAppTheme
  @Published var defaultWeather: String
  @Published var isAppLockEnabled: Bool
  @Published var isFaceIDEnabled: Bool
  @Published var passcodeDigitCount: Int
  @Published var lockGraceInterval: TimeInterval
  @Published var lockPasscodeInput = ""
  @Published var isUnlocked = false
  @Published var authErrorMessage = ""
  @Published var failedPasscodeAttempts: Int
  @Published var passcodeLockoutUntil: Date?
  @Published var passcodeLockoutDuration: TimeInterval
  @Published var obscuresAppSwitcher: Bool
  @Published var latestRecoveryKey = ""
  @Published var showSaveConfirmation = false
  @Published var saveConfirmationText = "오늘의 마음 하늘에 저장했어요"
  @Published var lastSavedEntryID: UUID?

  // MARK: - 캐시된 DateFormatter (성능 최적화)
  private static let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.timeStyle = .short
    return f
  }()

  private static let headerDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "M월 d일 EEEE"
    return f
  }()

  private static let shortDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "M월 d일"
    return f
  }()

  private static let fullDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateStyle = .full
    f.timeStyle = .short
    return f
  }()

  private static let monthTitleFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy년 M월"
    return f
  }()

  private static let syncTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.timeStyle = .short
    return f
  }()

  private static let backupFilenameFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyyMMdd-HHmmss"
    return f
  }()

  private func userFacingMessage(for error: Error, fallback: String) -> String {
    if let description = (error as? LocalizedError)?.errorDescription, !description.isEmpty {
      return description
    }
    return fallback
  }

  // MARK: - 상수
  let weathers = [("맑음", "☀️"), ("구름", "☁️"), ("비", "🌧️"), ("폭풍", "⛈️"), ("무지개", "🌈")]
  let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  let moodieTint = Color(red: 0.28, green: 0.48, blue: 0.58)
  let cardCornerRadius: CGFloat = 22
  let controlCornerRadius: CGFloat = 16

  let prompts = [
    "오늘 당신의 마음의 날씨는 어떤가요?",
    "오늘 하루는 어떠셨나요?",
    "오늘은 기분 좋은 일이 있었나요?",
    "지금 마음의 하늘은 어떤 모습인가요?",
    "오늘 마음에 남은 장면이 있나요?",
  ]
  let reminderBodies = [
    "오늘 마음 하늘은 어땠나요?",
    "잠깐, 마음 날씨 하나 남겨볼까요?",
    "오늘의 하늘을 조용히 기록해봐요.",
    "지금 마음은 어떤 날씨에 가까운가요?",
    "짧은 한 줄이면 충분해요.",
    "오늘을 지나가기 전에 마음을 살짝 놓아볼까요?",
    "기분의 색을 하나 골라둘 시간이에요.",
  ]

  let lockGraceOptions: [(label: String, seconds: TimeInterval)] = [
    ("즉시 다시 잠금", 0),
    ("30초 동안 열림 유지", 30),
    ("1분 동안 열림 유지", 60),
    ("5분 동안 열림 유지", 300),
  ]
  let passcodeLockoutOptions: [(label: String, seconds: TimeInterval)] = [
    ("30초 동안 입력 차단", 30),
    ("1분 동안 입력 차단", 60),
    ("5분 동안 입력 차단", 300),
  ]
  let saveMessages = [
    "오늘의 마음 하늘에 저장했어요",
    "나중의 나에게 조용히 남겨둘게요",
    "짧은 기록 하나가 오늘을 붙잡아줬어요",
    "방금 마음의 색을 잘 담아뒀어요",
    "오늘의 하늘 조각을 안전하게 보관했어요",
  ]

  let notePrompts = [
    "마음에 머무는 이야기를 적어보세요",
    "오늘의 마음을 조용히 털어놓아 보세요",
    "괜찮았던 일도, 무거웠던 일도 좋아요",
    "지금 마음속에 있는 말을 남겨보세요",
    "오늘을 한 문장으로 놓아두면 어떤 말인가요?",
  ]

  private let pendingDeleteIDsKey = "pending_cloud_delete_ids"
  private let swiftDataMigrationKey = "did_migrate_mood_entries_to_swiftdata"
  private let reminderEnabledKey = "is_moodie_reminder_enabled"
  private let reminderHourKey = "moodie_reminder_hour"
  private let reminderMinuteKey = "moodie_reminder_minute"
  private let reminderWeekdaysKey = "moodie_reminder_weekdays"
  private let reminderToneStyleKey = "moodie_reminder_tone_style"
  private let skipReminderAfterTodayEntryKey = "moodie_skip_reminder_after_today_entry"
  private let quietHoursEnabledKey = "moodie_quiet_hours_enabled"
  private let quietHoursStartKey = "moodie_quiet_hours_start"
  private let quietHoursEndKey = "moodie_quiet_hours_end"
  private let backupReminderEnabledKey = "moodie_backup_reminder_enabled"
  private let backupReminderDaysKey = "moodie_backup_reminder_days"
  private let lastBackupExportedAtKey = "moodie_last_backup_exported_at"
  private let preferredStartTabKey = "moodie_preferred_start_tab"
  private let dateDisplayStyleKey = "moodie_date_display_style"
  private let appThemeKey = "moodie_app_theme"
  private let defaultWeatherKey = "moodie_default_weather"
  private let appLockEnabledKey = "is_moodie_app_lock_enabled"
  private let faceIDEnabledKey = "is_moodie_face_id_enabled"
  private let passcodeHashKey = "moodie_passcode_hash"
  private let passcodeSaltKey = "moodie_passcode_salt"
  private let passcodeDigitCountKey = "moodie_passcode_digit_count"
  private let lockGraceIntervalKey = "moodie_lock_grace_interval"
  private let failedPasscodeAttemptsKey = "moodie_failed_passcode_attempts"
  private let passcodeLockoutUntilKey = "moodie_passcode_lockout_until"
  private let passcodeLockoutDurationKey = "moodie_passcode_lockout_duration"
  private let obscureAppSwitcherKey = "moodie_obscure_app_switcher"
  private let reminderNotificationID = "daily_moodie_sky_reminder"
  private var reminderNotificationIDs: [String] {
    (1...14).map { "\(reminderNotificationID)_rolling_\($0)" }
      + (1...7).map { "\(reminderNotificationID)_weekday_\($0)" }
      + ["\(reminderNotificationID)_backup"]
  }
  private let maxPasscodeAttempts = 5
  private let maxBackupImportBytes = 10 * 1024 * 1024
  private let maxBackupImportEntries = 5000
  private let maxImportedNoteCharacters = 2000
  private let earliestAllowedBackupDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? .distantPast
  private static let passcodeKeychainService = "com.mxvixxn.Moodie-Sky.passcode"
  private static let passcodeHashAccount = "passcode_hash"
  private static let passcodeSaltAccount = "passcode_salt"
  private static let recoveryKeyHashAccount = "recovery_key_hash"
  private static let recoveryKeySaltAccount = "recovery_key_salt"
  private var pendingDeleteIDs: [UUID] = []
  private var backgroundEnteredAt: Date?
  private var modelContext: ModelContext?

  // MARK: - 계산 프로퍼티
  var todayEntries: [MoodEntry] {
    entries.filter { Calendar.current.isDateInToday($0.date) }
  }
  var todayEntriesCount: Int { todayEntries.count }
  var remainingTodaySlots: Int { max(0, 3 - todayEntriesCount) }
  var canSaveToday: Bool { todayEntriesCount < 3 }
  var trimmedNote: String { note.trimmingCharacters(in: .whitespacesAndNewlines) }
  var canSubmitEntry: Bool { canSaveToday && !trimmedNote.isEmpty }
  var hasPasscode: Bool { Self.keychainString(account: Self.passcodeHashAccount) != nil }
  var hasRecoveryKey: Bool { Self.keychainString(account: Self.recoveryKeyHashAccount) != nil }
  var shouldShowLockScreen: Bool { isAppLockEnabled && !isUnlocked }
  var isPasscodeTemporarilyLocked: Bool {
    guard let passcodeLockoutUntil else { return false }
    return passcodeLockoutUntil > Date()
  }
  var passcodeLockoutMessage: String? {
    guard let passcodeLockoutUntil, passcodeLockoutUntil > Date() else { return nil }
    let seconds = max(1, Int(ceil(passcodeLockoutUntil.timeIntervalSinceNow)))
    return "암호 입력이 잠시 잠겼어요. \(seconds)초 뒤 다시 시도해주세요."
  }
  var todaySummaryTitle: String {
    guard let latest = todayEntries.first else { return "아직 오늘의 하늘은 비어 있어요" }
    return "오늘은 \(weatherStartPhrase(for: latest.weather)) 시작했어요"
  }
  var todaySummaryDetail: String {
    guard !todayEntries.isEmpty else { return "날씨 하나와 한 줄 메모로 오늘을 가볍게 시작해봐요." }
    return "남은 기록 \(remainingTodaySlots)개 · 오늘도 천천히 이어가요"
  }
  var todaySummaryEmoji: String { todayEntries.first?.emoji ?? selectedEmoji }
  var dataSummaryText: String {
    guard let firstDate = entries.map(\.date).min() else { return "아직 저장된 기록이 없어요." }
    return "총 \(entries.count)개 · 첫 기록 \(formattedDate(firstDate))"
  }
  var backupSummaryText: String {
    guard let lastBackupExportedAt else { return "아직 내보낸 백업이 없어요." }
    return "최근 백업: \(formattedFullDate(lastBackupExportedAt))"
  }

  // MARK: - 조사 처리 (개선)
  private func weatherStartPhrase(for weather: String) -> String {
    switch weather {
    case "맑음": return "맑음으로"
    case "구름": return "구름으로"
    case "폭풍": return "폭풍으로"
    case "비": return "비로"
    case "무지개": return "무지개로"
    default: return "\(weather)으로"
    }
  }

  private func weatherSubjectPhrase(for weather: String) -> String {
    switch weather {
    case "맑음": return "맑은 하늘이"
    case "구름": return "구름이"
    case "비": return "비가"
    case "폭풍": return "폭풍이"
    case "무지개": return "무지개가"
    default: return "\(weather)이"
    }
  }

  // MARK: - 초기화
  init() {
    let defaults = UserDefaults.standard
    isReminderEnabled = defaults.bool(forKey: reminderEnabledKey)
    let storedWeekdays = defaults.array(forKey: reminderWeekdaysKey) as? [Int]
    selectedReminderWeekdays = Set(storedWeekdays ?? Array(1...7))
    reminderToneStyle = ReminderToneStyle(
      rawValue: defaults.string(forKey: reminderToneStyleKey) ?? "random") ?? .random
    skipsReminderAfterTodayEntry = defaults.object(forKey: skipReminderAfterTodayEntryKey) as? Bool ?? true
    quietHoursEnabled = defaults.bool(forKey: quietHoursEnabledKey)
    backupReminderEnabled = defaults.object(forKey: backupReminderEnabledKey) as? Bool ?? true
    backupReminderDays = defaults.object(forKey: backupReminderDaysKey) as? Int ?? 14
    lastBackupExportedAt = defaults.object(forKey: lastBackupExportedAtKey) as? Date
    preferredStartTab = AppStartTab(rawValue: defaults.integer(forKey: preferredStartTabKey)) ?? .record
    dateDisplayStyle = MoodDateDisplayStyle(
      rawValue: defaults.string(forKey: dateDisplayStyleKey) ?? "korean") ?? .korean
    appTheme = MoodAppTheme(rawValue: defaults.string(forKey: appThemeKey) ?? "system") ?? .system
    defaultWeather = defaults.string(forKey: defaultWeatherKey) ?? "맑음"

    passcodeDigitCount = defaults.object(forKey: passcodeDigitCountKey) as? Int ?? 4
    lockGraceInterval = defaults.object(forKey: lockGraceIntervalKey) as? TimeInterval ?? 60
    passcodeLockoutDuration = defaults.object(forKey: passcodeLockoutDurationKey) as? TimeInterval ?? 60
    obscuresAppSwitcher = defaults.object(forKey: obscureAppSwitcherKey) as? Bool ?? true
    Self.migrateLegacyPasscodeIfNeeded(defaults: defaults)
    let hasStoredPasscode = Self.keychainString(account: Self.passcodeHashAccount) != nil
    failedPasscodeAttempts = defaults.integer(forKey: failedPasscodeAttemptsKey)
    passcodeLockoutUntil = defaults.object(forKey: passcodeLockoutUntilKey) as? Date
    isAppLockEnabled = hasStoredPasscode
    isFaceIDEnabled = hasStoredPasscode && defaults.bool(forKey: faceIDEnabledKey)

    var components = DateComponents()
    components.hour = defaults.object(forKey: reminderHourKey) as? Int ?? 21
    components.minute = defaults.object(forKey: reminderMinuteKey) as? Int ?? 0
    reminderTime = Calendar.current.date(from: components) ?? Date()

    var quietStartComponents = DateComponents()
    quietStartComponents.hour = defaults.object(forKey: quietHoursStartKey) as? Int ?? 22
    quietStartComponents.minute = 0
    quietHoursStart = Calendar.current.date(from: quietStartComponents) ?? Date()

    var quietEndComponents = DateComponents()
    quietEndComponents.hour = defaults.object(forKey: quietHoursEndKey) as? Int ?? 7
    quietEndComponents.minute = 0
    quietHoursEnd = Calendar.current.date(from: quietEndComponents) ?? Date()

    let defaultEmoji = Self.emoji(for: defaultWeather)
    selectedWeather = defaultWeather
    selectedEmoji = defaultEmoji

    todayPrompt = prompts.randomElement() ?? prompts[0]
    notePrompt = notePrompts.randomElement() ?? notePrompts[0]
    refreshPasscodeLockout()
  }

  func configure(modelContext: ModelContext) {
    guard self.modelContext == nil else { return }
    self.modelContext = modelContext
    migrateLegacyEntriesIfNeeded()
    loadEntries()
    loadPendingDeleteIDs()
    if isReminderEnabled { scheduleDailyReminder() }
  }

  // MARK: - 기록 저장 / 삭제 / 수정
  func saveEntry() {
    let noteToSave = trimmedNote
    guard canSaveToday, !noteToSave.isEmpty else { return }

    let newEntry = MoodEntry(
      id: UUID(),
      date: Date(),
      weather: selectedWeather,
      emoji: selectedEmoji,
      note: noteToSave
    )
    modelContext?.insert(newEntry)
    withAnimation {
      entries.insert(newEntry, at: 0)
      lastSavedEntryID = newEntry.id
      note = ""
      todayPrompt = prompts.randomElement() ?? prompts[0]
      notePrompt = notePrompts.randomElement() ?? notePrompts[0]
      saveConfirmationText = saveMessages.randomElement() ?? saveMessages[0]
    }
    showSaveConfirmationBriefly()
    saveEntries()
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    DispatchQueue.main.async { [weak self] in
      self?.hideKeyboard()
    }
    if isReminderEnabled { scheduleDailyReminder() }
    syncWithICloud()
  }

  private func showSaveConfirmationBriefly() {
    withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
      showSaveConfirmation = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) { [weak self] in
      guard let self else { return }
      withAnimation(.easeOut(duration: 0.22)) {
        self.showSaveConfirmation = false
        self.lastSavedEntryID = nil
      }
    }
  }

  func requestDelete(_ entry: MoodEntry) {
    entryToDelete = entry
    showDeleteAlert = true
    triggerSelectionHaptic()
  }

  func deleteConfirmed() {
    guard let entry = entryToDelete else { return }
    withAnimation { entries.removeAll { $0.id == entry.id } }
    modelContext?.delete(entry)
    pendingDeleteIDs.append(entry.id)
    saveEntries()
    savePendingDeleteIDs()
    triggerIntenseErrorHaptic()
    syncWithICloud()
  }

  func deleteAllEntries() {
    pendingDeleteIDs.append(contentsOf: entries.map { $0.id })
    entries.forEach { modelContext?.delete($0) }
    withAnimation { entries.removeAll() }
    saveEntries()
    savePendingDeleteIDs()
    triggerIntenseErrorHaptic()
    syncWithICloud()
  }

  func beginEditing(_ entry: MoodEntry) {
    editWeather = entry.weather
    editEmoji = entry.emoji
    editNote = entry.note
    entryToEdit = entry
    triggerSelectionHaptic()
  }

  func updateEntry(_ entry: MoodEntry) {
    let updatedNote = editNote.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !updatedNote.isEmpty,
      let index = entries.firstIndex(where: { $0.id == entry.id })
    else { return }

    entries[index].weather = editWeather
    entries[index].emoji = editEmoji
    entries[index].note = updatedNote
    entries[index].updatedAt = Date()
    entries[index].needsSync = true

    saveEntries()
    entryToEdit = nil
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    syncWithICloud()
  }

  // MARK: - 날짜 유틸리티
  func entriesForDay(_ date: Date) -> [MoodEntry] {
    entries
      .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
      .sorted { $0.date < $1.date }
  }

  func entriesForMonth(_ date: Date) -> [MoodEntry] {
    entries.filter {
      Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month)
    }
  }

  func monthlySummary(for date: Date) -> (emoji: String, title: String) {
    let monthEntries = entriesForMonth(date)
    guard !monthEntries.isEmpty else {
      return ("☁️", "아직 이번 달 마음 하늘은 비어 있어요")
    }
    let grouped = Dictionary(grouping: monthEntries, by: { $0.weather })
    let mostFrequent = grouped.max { $0.value.count < $1.value.count }
    let weather = mostFrequent?.key ?? "구름"
    let emoji = weathers.first { $0.0 == weather }?.1 ?? "☁️"
    return (emoji, "\(weather)이 가장 많았어요")
  }

  func weeklyReport(for date: Date) -> MoodReport {
    let calendar = Calendar.current
    let interval = calendar.dateInterval(of: .weekOfYear, for: date)
    let weekEntries = entries.filter { entry in
      guard let interval else { return false }
      return interval.contains(entry.date)
    }
    let previousEntries: [MoodEntry]
    if let interval,
      let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: interval.start),
      let previousInterval = calendar.dateInterval(of: .weekOfYear, for: previousStart)
    {
      previousEntries = entries.filter { previousInterval.contains($0.date) }
    } else {
      previousEntries = []
    }
    return report(
      title: "이번 주 리포트",
      entries: weekEntries,
      previousEntries: previousEntries,
      emptyText: "이번 주 마음 하늘은 아직 조용해요"
    )
  }

  func monthlyReport(for date: Date) -> MoodReport {
    let calendar = Calendar.current
    let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) ?? date
    return report(
      title: "이번 달 리포트",
      entries: entriesForMonth(date),
      previousEntries: entriesForMonth(previousMonth),
      emptyText: "이번 달 마음 하늘은 아직 비어 있어요"
    )
  }

  private func report(
    title: String, entries: [MoodEntry], previousEntries: [MoodEntry], emptyText: String
  ) -> MoodReport {
    let comparison = reportComparison(current: entries, previous: previousEntries)
    guard !entries.isEmpty else {
      return MoodReport(
        title: title,
        emoji: "☁️",
        headline: emptyText,
        detail: "기록이 쌓이면 이 기간의 하늘을 조용히 모아볼게요.",
        comparison: comparison,
        insight: "아직은 비워두어도 괜찮아요.",
        entriesCount: 0,
        activeDaysCount: 0
      )
    }

    let grouped = Dictionary(grouping: entries, by: { $0.weather })
    let dominant = grouped.max { $0.value.count < $1.value.count }
    let weather = dominant?.key ?? "구름"
    let emoji = weathers.first { $0.0 == weather }?.1 ?? "☁️"
    let activeDays = Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    let noteLengths = entries.map { $0.note.trimmingCharacters(in: .whitespacesAndNewlines).count }
    let averageNoteLength = noteLengths.isEmpty ? 0 : noteLengths.reduce(0, +) / noteLengths.count
    let detail: String
    let insight = reportInsight(entries: entries, dominantWeather: weather)

    if averageNoteLength >= 24 {
      detail = "조금 더 오래 머문 마음들이 있었어요."
    } else if activeDays >= 4 {
      detail = "여러 날에 걸쳐 하늘이 차분히 이어졌어요."
    } else {
      detail = "짧은 기록들이 이 기간의 분위기를 만들었어요."
    }

    return MoodReport(
      title: title,
      emoji: emoji,
      headline: "이번 기간은 \(weatherSubjectPhrase(for: weather)) 자주 머물렀어요",
      detail: detail,
      comparison: comparison,
      insight: insight,
      entriesCount: entries.count,
      activeDaysCount: activeDays
    )
  }

  private func reportInsight(entries: [MoodEntry], dominantWeather: String) -> String {
    let calendar = Calendar.current
    let weekendEntries = entries.filter {
      [1, 7].contains(calendar.component(.weekday, from: $0.date))
    }
    let weekdayEntries = entries.filter {
      ![1, 7].contains(calendar.component(.weekday, from: $0.date))
    }

    if weekendEntries.count >= 2 {
      let weekendWeather = mostFrequentWeather(in: weekendEntries)
      if weekendWeather == dominantWeather {
        return "주말에도 비슷한 하늘이 이어졌어요."
      }
      return "주말에는 \(weatherSubjectPhrase(for: weekendWeather)) 조금 더 눈에 띄었어요."
    }

    let groupedByWeather = Dictionary(grouping: entries, by: { $0.weather })
    let longestNoteWeather = groupedByWeather.max { lhs, rhs in
      averageNoteLength(for: lhs.value) < averageNoteLength(for: rhs.value)
    }?.key

    if let longestNoteWeather, entries.count >= 3 {
      return "\(weatherSubjectPhrase(for: longestNoteWeather)) 남긴 말이 조금 더 길었어요."
    }

    if weekdayEntries.count >= 3 {
      return "평일의 하늘이 차곡차곡 남았어요."
    }

    return "\(weatherSubjectPhrase(for: dominantWeather)) 중심으로 작은 분위기가 보이기 시작했어요."
  }

  private func mostFrequentWeather(in entries: [MoodEntry]) -> String {
    let grouped = Dictionary(grouping: entries, by: { $0.weather })
    return grouped.max { $0.value.count < $1.value.count }?.key ?? "구름"
  }

  private func averageNoteLength(for entries: [MoodEntry]) -> Int {
    guard !entries.isEmpty else { return 0 }
    let total = entries.map { $0.note.trimmingCharacters(in: .whitespacesAndNewlines).count }
      .reduce(0, +)
    return total / entries.count
  }

  private func reportComparison(current: [MoodEntry], previous: [MoodEntry]) -> String {
    guard !current.isEmpty else {
      return previous.isEmpty ? "비교할 기록은 아직 기다리는 중이에요." : "이번 기간은 잠시 쉬어가는 중이에요."
    }
    guard !previous.isEmpty else {
      return "새로운 기록이 쌓이기 시작했어요."
    }
    let delta = current.count - previous.count
    if delta > 0 {
      return "지난 기간보다 \(delta)번 더 자주 남겼어요."
    } else if delta < 0 {
      return "지난 기간보다 \(-delta)번 적게 남겼어요."
    } else {
      return "지난 기간과 비슷한 리듬이에요."
    }
  }

  // MARK: - 날짜 포매터 (캐시된 인스턴스 사용)
  func timeText(_ date: Date) -> String {
    Self.timeFormatter.string(from: date)
  }

  func formattedHeaderDate(_ date: Date) -> String {
    switch dateDisplayStyle {
    case .korean: return Self.headerDateFormatter.string(from: date)
    case .numeric:
      let f = DateFormatter()
      f.dateFormat = "yyyy.MM.dd EEEE"
      f.locale = Locale(identifier: "ko_KR")
      return f.string(from: date)
    case .compact:
      let f = DateFormatter()
      f.dateFormat = "M/d E"
      f.locale = Locale(identifier: "ko_KR")
      return f.string(from: date)
    }
  }

  func formattedDate(_ date: Date) -> String {
    switch dateDisplayStyle {
    case .korean: return Self.shortDateFormatter.string(from: date)
    case .numeric:
      let f = DateFormatter()
      f.dateFormat = "yyyy.MM.dd"
      return f.string(from: date)
    case .compact:
      let f = DateFormatter()
      f.dateFormat = "M/d"
      return f.string(from: date)
    }
  }

  func formattedFullDate(_ date: Date) -> String {
    switch dateDisplayStyle {
    case .korean: return Self.fullDateFormatter.string(from: date)
    case .numeric:
      let f = DateFormatter()
      f.locale = Locale(identifier: "ko_KR")
      f.dateFormat = "yyyy.MM.dd HH:mm"
      return f.string(from: date)
    case .compact:
      let f = DateFormatter()
      f.locale = Locale(identifier: "ko_KR")
      f.dateFormat = "M/d HH:mm"
      return f.string(from: date)
    }
  }

  func monthTitle(_ date: Date) -> String {
    Self.monthTitleFormatter.string(from: date)
  }

  // MARK: - 달력
  func calendarDays(for month: Date) -> [CalendarDay] {
    let calendar = Calendar.current
    guard
      let monthInterval = calendar.dateInterval(of: .month, for: month),
      let dayRange = calendar.range(of: .day, in: .month, for: month)
    else { return [] }

    let firstDayOfMonth = monthInterval.start
    let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth) - 1

    let emptyLeadingDays = (0..<weekdayOfFirst).map {
      CalendarDay(id: "empty_\($0)", date: nil)
    }

    let actualDays = dayRange.compactMap { dayOffset -> CalendarDay? in
      guard
        let date = calendar.date(
          byAdding: .day,
          value: dayOffset - 1,
          to: firstDayOfMonth
        )
      else { return nil }
      return CalendarDay(id: "day_\(dayOffset)", date: date)
    }

    return emptyLeadingDays + actualDays
  }

  // MARK: - 배경색
  func accentColor(for weather: String) -> Color {
    switch weather {
    case "맑음":
      return Color(red: 0.88, green: 0.60, blue: 0.28)
    case "구름":
      return moodieTint
    case "비":
      return Color(red: 0.36, green: 0.54, blue: 0.78)
    case "폭풍":
      return Color(red: 0.47, green: 0.42, blue: 0.66)
    case "무지개":
      return Color(red: 0.77, green: 0.42, blue: 0.58)
    default:
      return moodieTint
    }
  }

  func backgroundColors() -> [Color] {
    backgroundColors(for: selectedWeather)
  }

  func backgroundColors(for weather: String) -> [Color] {
    switch weather {
    case "맑음":
      return [
        Color(red: 0.78, green: 0.90, blue: 0.94).opacity(0.55),
        Color(red: 0.98, green: 0.93, blue: 0.74).opacity(0.34),
        Color(.systemGroupedBackground),
      ]
    case "구름":
      return [
        Color(red: 0.76, green: 0.82, blue: 0.86).opacity(0.54),
        Color(red: 0.91, green: 0.94, blue: 0.95).opacity(0.42),
        Color(.systemGroupedBackground),
      ]
    case "비":
      return [
        Color(red: 0.50, green: 0.66, blue: 0.82).opacity(0.48),
        Color(red: 0.62, green: 0.72, blue: 0.86).opacity(0.34),
        Color(.systemGroupedBackground),
      ]
    case "폭풍":
      return [
        Color(red: 0.36, green: 0.40, blue: 0.56).opacity(0.50),
        Color(red: 0.58, green: 0.50, blue: 0.68).opacity(0.36),
        Color(.systemGroupedBackground),
      ]
    case "무지개":
      return [
        Color(red: 0.96, green: 0.78, blue: 0.82).opacity(0.40),
        Color(red: 0.72, green: 0.90, blue: 0.88).opacity(0.30),
        Color(.systemGroupedBackground),
      ]
    default:
      return [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)]
    }
  }

  func weekdayColor(_ day: String) -> Color {
    switch day {
    case "Sun": return .red
    case "Sat": return .blue
    default: return .secondary
    }
  }

  // MARK: - 햅틱
  func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
  }

  func triggerSelectionHaptic() {
    let generator = UISelectionFeedbackGenerator()
    generator.prepare()
    generator.selectionChanged()
  }

  func triggerIntenseErrorHaptic() {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.error)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      generator.notificationOccurred(.error)
    }
  }

  // MARK: - 기타
  func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil, from: nil, for: nil
    )
  }

  func changeMonth(_ value: Int) {
    withAnimation {
      if let next = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
        displayedMonth = next
      }
    }
  }

  func finishOnboarding() {
    UserDefaults.standard.set(true, forKey: "hasSeenMoodieTutorial")
  }

  func limitedDigits(_ value: String, count: Int) -> String {
    String(value.filter { $0.isNumber }.prefix(count))
  }

  // MARK: - 일반 설정
  func setPreferredStartTab(_ tab: AppStartTab) {
    preferredStartTab = tab
    UserDefaults.standard.set(tab.rawValue, forKey: preferredStartTabKey)
  }

  func setDateDisplayStyle(_ style: MoodDateDisplayStyle) {
    dateDisplayStyle = style
    UserDefaults.standard.set(style.rawValue, forKey: dateDisplayStyleKey)
  }

  func setAppTheme(_ theme: MoodAppTheme) {
    appTheme = theme
    UserDefaults.standard.set(theme.rawValue, forKey: appThemeKey)
  }

  func setDefaultWeather(_ weather: String) {
    guard let match = weathers.first(where: { $0.0 == weather }) else { return }
    defaultWeather = match.0
    selectedWeather = match.0
    selectedEmoji = match.1
    UserDefaults.standard.set(match.0, forKey: defaultWeatherKey)
  }

  // MARK: - 알림 설정
  func toggleReminderWeekday(_ weekday: Int) {
    guard (1...7).contains(weekday) else { return }
    if selectedReminderWeekdays.contains(weekday), selectedReminderWeekdays.count > 1 {
      selectedReminderWeekdays.remove(weekday)
    } else {
      selectedReminderWeekdays.insert(weekday)
    }
    UserDefaults.standard.set(Array(selectedReminderWeekdays).sorted(), forKey: reminderWeekdaysKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func setReminderToneStyle(_ style: ReminderToneStyle) {
    reminderToneStyle = style
    UserDefaults.standard.set(style.rawValue, forKey: reminderToneStyleKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func setSkipsReminderAfterTodayEntry(_ shouldSkip: Bool) {
    skipsReminderAfterTodayEntry = shouldSkip
    UserDefaults.standard.set(shouldSkip, forKey: skipReminderAfterTodayEntryKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func setQuietHoursEnabled(_ isEnabled: Bool) {
    quietHoursEnabled = isEnabled
    UserDefaults.standard.set(isEnabled, forKey: quietHoursEnabledKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func updateQuietHoursStart(_ date: Date) {
    quietHoursStart = date
    let hour = Calendar.current.component(.hour, from: date)
    UserDefaults.standard.set(hour, forKey: quietHoursStartKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func updateQuietHoursEnd(_ date: Date) {
    quietHoursEnd = date
    let hour = Calendar.current.component(.hour, from: date)
    UserDefaults.standard.set(hour, forKey: quietHoursEndKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func setBackupReminderEnabled(_ isEnabled: Bool) {
    backupReminderEnabled = isEnabled
    UserDefaults.standard.set(isEnabled, forKey: backupReminderEnabledKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func setBackupReminderDays(_ days: Int) {
    backupReminderDays = min(max(days, 7), 90)
    UserDefaults.standard.set(backupReminderDays, forKey: backupReminderDaysKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  // MARK: - 알림
  func setReminderEnabled(_ isEnabled: Bool) {
    isReminderEnabled = isEnabled
    UserDefaults.standard.set(isEnabled, forKey: reminderEnabledKey)
    if isEnabled {
      scheduleDailyReminder()
    } else {
      removeScheduledReminders()
    }
  }

  func updateReminderTime(_ date: Date) {
    reminderTime = date
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    UserDefaults.standard.set(components.hour ?? 21, forKey: reminderHourKey)
    UserDefaults.standard.set(components.minute ?? 0, forKey: reminderMinuteKey)
    if isReminderEnabled { scheduleDailyReminder() }
  }
  func scheduleDailyReminder() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
      DispatchQueue.main.async {
        guard let self else { return }
        if let error {
          self.isReminderEnabled = false
          UserDefaults.standard.set(false, forKey: self.reminderEnabledKey)
          self.syncStatus = .failed(
            self.userFacingMessage(
              for: error,
              fallback: "알림 설정을 완료하지 못했어요. 잠시 후 다시 시도해주세요."
            )
          )
          return
        }
        guard granted else {
          self.isReminderEnabled = false
          UserDefaults.standard.set(false, forKey: self.reminderEnabledKey)
          self.syncStatus = .failed("알림 권한이 꺼져 있어요. 설정 앱에서 허용할 수 있어요.")
          return
        }

        self.removeScheduledReminders()
        self.scheduleRollingMoodReminders(center: center)
        self.scheduleBackupReminderIfNeeded(center: center)
      }
    }
  }

  private func scheduleRollingMoodReminders(center: UNUserNotificationCenter) {
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
    var scheduledCount = 0

    for dayOffset in 0..<21 where scheduledCount < 14 {
      guard
        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()),
        selectedReminderWeekdays.contains(calendar.component(.weekday, from: date)),
        !shouldSkipReminder(on: date),
        !isQuietHour(date: date, hour: timeComponents.hour ?? 21)
      else { continue }

      var components = calendar.dateComponents([.year, .month, .day], from: date)
      components.hour = timeComponents.hour
      components.minute = timeComponents.minute

      guard let fireDate = calendar.date(from: components), fireDate > Date() else { continue }

      let content = UNMutableNotificationContent()
      content.title = "Moodie Sky"
      content.body = reminderBody(for: scheduledCount)
      content.sound = .default

      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      let request = UNNotificationRequest(
        identifier: "\(reminderNotificationID)_rolling_\(scheduledCount + 1)",
        content: content,
        trigger: trigger
      )
      center.add(request) { [weak self] error in
        if let error {
          DispatchQueue.main.async {
            self?.syncStatus = .failed(
              self?.userFacingMessage(
                for: error,
                fallback: "알림 예약을 완료하지 못했어요. 알림 설정을 다시 확인해주세요."
              ) ?? "알림 예약을 완료하지 못했어요. 알림 설정을 다시 확인해주세요."
            )
          }
        }
      }
      scheduledCount += 1
    }
  }

  private func scheduleBackupReminderIfNeeded(center: UNUserNotificationCenter) {
    guard backupReminderEnabled else { return }
    let calendar = Calendar.current
    let last = lastBackupExportedAt ?? entries.map(\.date).min() ?? Date()
    guard let fireDate = calendar.date(byAdding: .day, value: backupReminderDays, to: last), fireDate > Date() else { return }

    var components = calendar.dateComponents([.year, .month, .day], from: fireDate)
    components.hour = 10
    components.minute = 0

    let content = UNMutableNotificationContent()
    content.title = "Moodie Sky"
    content.body = "기록이 쌓였어요. 백업을 한 번 남겨둘까요?"
    content.sound = .default

    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    let request = UNNotificationRequest(
      identifier: "\(reminderNotificationID)_backup",
      content: content,
      trigger: trigger
    )
    center.add(request)
  }

  private func shouldSkipReminder(on date: Date) -> Bool {
    guard skipsReminderAfterTodayEntry else { return false }
    return entries.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
  }

  private func isQuietHour(date: Date, hour: Int) -> Bool {
    guard quietHoursEnabled else { return false }
    let calendar = Calendar.current
    let start = calendar.component(.hour, from: quietHoursStart)
    let end = calendar.component(.hour, from: quietHoursEnd)
    if start < end { return hour >= start && hour < end }
    return hour >= start || hour < end
  }

  private func reminderBody(for index: Int) -> String {
    let streak = currentStreakDays()
    let suffix = streak >= 2 ? " \(streak)일째 이어지고 있어요." : ""
    switch reminderToneStyle {
    case .gentle:
      return "오늘 마음 하늘은 어땠나요?\(suffix)"
    case .short:
      return "마음 날씨를 남겨볼까요?\(suffix)"
    case .random:
      return (reminderBodies[index % reminderBodies.count]) + suffix
    }
  }

  private func currentStreakDays() -> Int {
    let calendar = Calendar.current
    let days = Set(entries.map { calendar.startOfDay(for: $0.date) })
    var streak = 0
    var cursor = calendar.startOfDay(for: Date())
    while days.contains(cursor) {
      streak += 1
      guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
      cursor = previous
    }
    return streak
  }

  private func removeScheduledReminders() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: reminderNotificationIDs + [reminderNotificationID]
    )
  }

  // MARK: - 잠금
  func updateLockGraceInterval(_ interval: TimeInterval) {
    guard lockGraceOptions.contains(where: { $0.seconds == interval }) else { return }
    lockGraceInterval = interval
    UserDefaults.standard.set(interval, forKey: lockGraceIntervalKey)
  }

  func updatePasscodeLockoutDuration(_ duration: TimeInterval) {
    guard passcodeLockoutOptions.contains(where: { $0.seconds == duration }) else { return }
    passcodeLockoutDuration = duration
    UserDefaults.standard.set(duration, forKey: passcodeLockoutDurationKey)
  }

  func setObscuresAppSwitcher(_ isEnabled: Bool) {
    obscuresAppSwitcher = isEnabled
    UserDefaults.standard.set(isEnabled, forKey: obscureAppSwitcherKey)
  }

  func updatePasscodeDigitCount(_ digitCount: Int) {
    guard digitCount == 4 || digitCount == 6 else { return }
    passcodeDigitCount = digitCount
    UserDefaults.standard.set(digitCount, forKey: passcodeDigitCountKey)
  }

  func setPasscode(_ passcode: String, confirmation: String, digitCount: Int) -> Bool {
    let trimmedPasscode = passcode.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedConfirmation = confirmation.trimmingCharacters(in: .whitespacesAndNewlines)

    guard digitCount == 4 || digitCount == 6 else { return false }
    guard trimmedPasscode.count == digitCount,
      trimmedPasscode.allSatisfy(\.isNumber)
    else {
      authErrorMessage = "\(digitCount)자리 숫자 암호를 입력해주세요."
      return false
    }
    guard trimmedPasscode == trimmedConfirmation else {
      authErrorMessage = "암호가 서로 달라요. 다시 확인해주세요."
      return false
    }

    let salt = UUID().uuidString
    let recoveryKey = makeRecoveryKey()
    guard Self.setKeychainString(salt, account: Self.passcodeSaltAccount),
      Self.setKeychainString(hashPasscode(trimmedPasscode, salt: salt), account: Self.passcodeHashAccount)
    else {
      authErrorMessage = "암호를 안전하게 저장하지 못했어요. 다시 시도해주세요."
      return false
    }
    UserDefaults.standard.removeObject(forKey: passcodeHashKey)
    UserDefaults.standard.removeObject(forKey: passcodeSaltKey)
    UserDefaults.standard.set(digitCount, forKey: passcodeDigitCountKey)
    UserDefaults.standard.set(true, forKey: appLockEnabledKey)
    passcodeDigitCount = digitCount
    isAppLockEnabled = true
    isUnlocked = true
    lockPasscodeInput = ""
    authErrorMessage = ""
    latestRecoveryKey = recoveryKey
    return true
  }

  func confirmLatestRecoveryKey(_ recoveryKey: String) -> Bool {
    guard !latestRecoveryKey.isEmpty else {
      authErrorMessage = "확인할 복구키가 없어요. 앱 암호를 다시 설정해주세요."
      return false
    }
    guard normalizedRecoveryKey(recoveryKey) == normalizedRecoveryKey(latestRecoveryKey) else {
      authErrorMessage = "복구키가 맞지 않아요. 저장한 키를 다시 확인해주세요."
      return false
    }

    let recoverySalt = UUID().uuidString
    guard Self.setKeychainString(recoverySalt, account: Self.recoveryKeySaltAccount),
      Self.setKeychainString(
        hashRecoveryKey(latestRecoveryKey, salt: recoverySalt),
        account: Self.recoveryKeyHashAccount
      )
    else {
      authErrorMessage = "복구키를 안전하게 저장하지 못했어요. 다시 시도해주세요."
      return false
    }
    authErrorMessage = ""
    latestRecoveryKey = ""
    return true
  }

  func removePasscode() {
    Self.deleteKeychainItem(account: Self.passcodeHashAccount)
    Self.deleteKeychainItem(account: Self.passcodeSaltAccount)
    Self.deleteKeychainItem(account: Self.recoveryKeyHashAccount)
    Self.deleteKeychainItem(account: Self.recoveryKeySaltAccount)
    UserDefaults.standard.removeObject(forKey: passcodeHashKey)
    UserDefaults.standard.removeObject(forKey: passcodeSaltKey)
    UserDefaults.standard.set(false, forKey: appLockEnabledKey)
    UserDefaults.standard.set(false, forKey: faceIDEnabledKey)
    resetPasscodeFailures()
    isAppLockEnabled = false
    isFaceIDEnabled = false
    isUnlocked = false
    lockPasscodeInput = ""
    authErrorMessage = ""
    latestRecoveryKey = ""
  }

  func resetPasscodeWithRecoveryKey(
    _ recoveryKey: String,
    newPasscode: String,
    confirmation: String,
    digitCount: Int
  ) -> Bool {
    guard hasRecoveryKey else {
      authErrorMessage = "저장된 복구키가 없어요. 기록 삭제 후 초기화가 필요해요."
      return false
    }
    guard verifyRecoveryKey(recoveryKey) else {
      registerFailedPasscodeAttempt()
      return false
    }
    resetPasscodeFailures()
    return setPasscode(newPasscode, confirmation: confirmation, digitCount: digitCount)
  }

  func resetLocalDataAndSecurity() {
    entries.forEach { modelContext?.delete($0) }
    withAnimation { entries.removeAll() }
    pendingDeleteIDs.removeAll()
    selectedEntry = nil
    entryToEdit = nil
    entryToDelete = nil
    showDeleteAlert = false
    showAllDeleteAlert = false
    note = ""
    lockPasscodeInput = ""

    Self.deleteKeychainItem(account: Self.passcodeHashAccount)
    Self.deleteKeychainItem(account: Self.passcodeSaltAccount)
    Self.deleteKeychainItem(account: Self.recoveryKeyHashAccount)
    Self.deleteKeychainItem(account: Self.recoveryKeySaltAccount)

    UserDefaults.standard.removeObject(forKey: passcodeHashKey)
    UserDefaults.standard.removeObject(forKey: passcodeSaltKey)
    UserDefaults.standard.removeObject(forKey: pendingDeleteIDsKey)
    UserDefaults.standard.removeObject(forKey: failedPasscodeAttemptsKey)
    UserDefaults.standard.removeObject(forKey: passcodeLockoutUntilKey)
    UserDefaults.standard.set(false, forKey: appLockEnabledKey)
    UserDefaults.standard.set(false, forKey: faceIDEnabledKey)

    resetPasscodeFailures()
    isAppLockEnabled = false
    isFaceIDEnabled = false
    isUnlocked = true
    authErrorMessage = ""
    latestRecoveryKey = ""
    syncStatus = .idle
    saveEntries()
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  func setFaceIDEnabled(_ isEnabled: Bool) {
    guard hasPasscode else {
      isFaceIDEnabled = false
      authErrorMessage = "먼저 앱 암호를 만들어주세요."
      return
    }
    if isEnabled {
      authenticateWithBiometrics { [weak self] success in
        guard let self else { return }
        self.isFaceIDEnabled = success
        UserDefaults.standard.set(success, forKey: self.faceIDEnabledKey)
      }
    } else {
      isFaceIDEnabled = false
      UserDefaults.standard.set(false, forKey: faceIDEnabledKey)
    }
  }

  func noteAppDidEnterBackground() {
    guard isAppLockEnabled else { return }
    backgroundEnteredAt = Date()
  }

  func handleAppDidBecomeActive() {
    guard isAppLockEnabled else { return }
    guard let backgroundEnteredAt else { return }
    if Date().timeIntervalSince(backgroundEnteredAt) >= lockGraceInterval {
      isUnlocked = false
      lockPasscodeInput = ""
      authErrorMessage = ""
    }
    self.backgroundEnteredAt = nil
  }

  func lockIfNeeded() {
    noteAppDidEnterBackground()
  }

  func unlockWithBiometricsIfAvailable() {
    guard shouldShowLockScreen, isFaceIDEnabled else { return }
    authenticateWithBiometrics { [weak self] success in
      guard let self, success else { return }
      self.isUnlocked = true
      self.lockPasscodeInput = ""
    }
  }

  func unlockWithPasscode() {
    guard validatePasscodeForProtectedAction(lockPasscodeInput) else {
      lockPasscodeInput = ""
      triggerIntenseErrorHaptic()
      return
    }
    isUnlocked = true
    lockPasscodeInput = ""
    authErrorMessage = ""
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  func appendLockPasscodeDigit(_ digit: String) {
    refreshPasscodeLockout()
    guard !isPasscodeTemporarilyLocked else {
      authErrorMessage = passcodeLockoutMessage ?? "암호 입력이 잠시 잠겼어요."
      return
    }
    guard digit.count == 1,
      digit.allSatisfy(\.isNumber),
      lockPasscodeInput.count < passcodeDigitCount
    else { return }

    lockPasscodeInput.append(digit)
    triggerHaptic(.light)
    authErrorMessage = ""

    if lockPasscodeInput.count == passcodeDigitCount {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
        self?.unlockWithPasscode()
      }
    }
  }

  func deleteLockPasscodeDigit() {
    guard !lockPasscodeInput.isEmpty else { return }
    lockPasscodeInput.removeLast()
    triggerHaptic(.soft)
  }

  func refreshPasscodeLockout() {
    guard let passcodeLockoutUntil else { return }
    if passcodeLockoutUntil <= Date() {
      resetPasscodeFailures()
    }
  }

  func validatePasscodeForProtectedAction(_ passcode: String) -> Bool {
    refreshPasscodeLockout()
    guard !isPasscodeTemporarilyLocked else {
      authErrorMessage = passcodeLockoutMessage ?? "암호 입력이 잠시 잠겼어요."
      return false
    }
    guard verifyPasscode(passcode) else {
      registerFailedPasscodeAttempt()
      return false
    }
    resetPasscodeFailures()
    authErrorMessage = ""
    return true
  }

  private func registerFailedPasscodeAttempt() {
    failedPasscodeAttempts += 1
    UserDefaults.standard.set(failedPasscodeAttempts, forKey: failedPasscodeAttemptsKey)

    if failedPasscodeAttempts >= maxPasscodeAttempts {
      let until = Date().addingTimeInterval(passcodeLockoutDuration)
      passcodeLockoutUntil = until
      UserDefaults.standard.set(until, forKey: passcodeLockoutUntilKey)
      authErrorMessage = passcodeLockoutMessage ?? "암호 입력이 잠시 잠겼어요."
    } else {
      let remaining = maxPasscodeAttempts - failedPasscodeAttempts
      authErrorMessage = "암호가 맞지 않아요. 남은 시도 \(remaining)번."
    }
  }

  private func resetPasscodeFailures() {
    failedPasscodeAttempts = 0
    passcodeLockoutUntil = nil
    UserDefaults.standard.removeObject(forKey: failedPasscodeAttemptsKey)
    UserDefaults.standard.removeObject(forKey: passcodeLockoutUntilKey)
  }

  func authenticateProtectedActionWithBiometrics(completion: @escaping (Bool) -> Void) {
    guard hasPasscode else {
      authErrorMessage = "먼저 앱 암호를 만들어주세요."
      completion(false)
      return
    }
    refreshPasscodeLockout()
    guard !isPasscodeTemporarilyLocked else {
      authErrorMessage = passcodeLockoutMessage ?? "암호 입력이 잠시 잠겼어요."
      completion(false)
      return
    }
    authenticateWithBiometrics { success in
      completion(success)
    }
  }

  func prepareBackupExport(passcode: String, format: BackupExportFormat, backupPassword: String? = nil) -> URL? {
    guard hasPasscode else {
      authErrorMessage = "백업을 내보내려면 먼저 앱 암호를 만들어주세요."
      return nil
    }
    guard validatePasscodeForProtectedAction(passcode) else { return nil }
    return makeBackupFileURL(format: format, backupPassword: backupPassword)
  }

  func prepareAuthenticatedBackupExport(format: BackupExportFormat, backupPassword: String? = nil) -> URL? {
    makeBackupFileURL(format: format, backupPassword: backupPassword)
  }

  func prepareBackupExportWithBiometrics(
    format: BackupExportFormat,
    backupPassword: String? = nil,
    completion: @escaping (URL?) -> Void
  ) {
    guard hasPasscode else {
      authErrorMessage = "백업을 내보내려면 먼저 앱 암호를 만들어주세요."
      completion(nil)
      return
    }
    refreshPasscodeLockout()
    guard !isPasscodeTemporarilyLocked else {
      authErrorMessage = passcodeLockoutMessage ?? "암호 입력이 잠시 잠겼어요."
      completion(nil)
      return
    }
    authenticateWithBiometrics { [weak self] success in
      guard let self, success else {
        completion(nil)
        return
      }
      completion(self.makeBackupFileURL(format: format, backupPassword: backupPassword))
    }
  }

  private func makeBackupFileURL(format: BackupExportFormat, backupPassword: String? = nil) -> URL? {
    saveEntries()

    do {
      let data: Data
      switch format {
      case .csv:
        data = makeBackupCSVData()
      case .json:
        data = try makeBackupJSONData()
      case .encryptedJSON:
        guard let backupPassword, backupPassword.count >= 8 else { throw BackupImportError.weakBackupPassword }
        data = try makeEncryptedBackupData(password: backupPassword)
      }

      let filename = "MoodieSky-Backup-\(Self.backupFilenameFormatter.string(from: Date())).\(format.fileExtension)"
      let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
      try data.write(to: url, options: [.atomic, .completeFileProtection])
      lastBackupExportedAt = Date()
      UserDefaults.standard.set(lastBackupExportedAt, forKey: lastBackupExportedAtKey)
      if isReminderEnabled { scheduleDailyReminder() }
      authErrorMessage = ""
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      return url
    } catch {
      authErrorMessage = userFacingMessage(
        for: error,
        fallback: "백업 파일을 만들지 못했어요. 다시 시도해주세요."
      )
      return nil
    }
  }

  private func backupSafeEntries() -> [MoodEntry] {
    entries.sorted { $0.date > $1.date }.map { entry in
      MoodEntry(
        id: entry.id,
        date: entry.date,
        weather: entry.weather,
        emoji: entry.emoji,
        note: entry.note,
        intensity: entry.intensity,
        updatedAt: entry.updatedAt,
        needsSync: true,
        cloudRecordName: nil
      )
    }
  }

  private func makeEncryptedBackupData(password: String) throws -> Data {
    let plaintext = try makeBackupJSONData()
    let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
    let key = backupEncryptionKey(password: password, salt: salt)
    let sealedBox = try AES.GCM.seal(plaintext, using: key)
    guard let combined = sealedBox.combined else { throw BackupImportError.invalidBackupPassword }
    let payload = EncryptedBackupPayload(
      appName: "Moodie Sky",
      schemaVersion: 1,
      algorithm: "AES-GCM-HKDF-SHA256",
      salt: salt,
      sealedData: combined,
      exportedAt: Date()
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(payload)
  }

  private func makeBackupJSONData() throws -> Data {
    let payload = MoodBackupPayload(
      appName: "Moodie Sky",
      schemaVersion: 1,
      exportedAt: Date(),
      entries: backupSafeEntries()
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(payload)
  }

  private func makeBackupCSVData() -> Data {
    let formatter = ISO8601DateFormatter()
    var rows = [[
      "id", "date", "weather", "emoji", "note", "intensity", "updatedAt",
    ]]

    for entry in backupSafeEntries() {
      rows.append([
        entry.id.uuidString,
        formatter.string(from: entry.date),
        entry.weather,
        entry.emoji,
        entry.note,
        String(entry.intensity),
        formatter.string(from: entry.updatedAt),
      ])
    }

    let csv = rows.map { row in row.map(csvEscaped).joined(separator: ",") }.joined(separator: "\n")
    return Data(("\u{FEFF}" + csv + "\n").utf8)
  }

  private func csvEscaped(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  func backupImportPreview(from url: URL, backupPassword: String? = nil) -> BackupImportPreview? {
    do {
      let importedEntries = try loadBackupEntries(from: url, backupPassword: backupPassword)
      let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
      let newCount = importedEntries.filter { byID[$0.id] == nil }.count
      let updatedCount = importedEntries.filter { imported in
        guard let existing = byID[imported.id] else { return false }
        return imported.updatedAt > existing.updatedAt
      }.count
      return BackupImportPreview(
        totalEntries: importedEntries.count,
        newEntries: newCount,
        updatedEntries: updatedCount,
        unchangedEntries: max(0, importedEntries.count - newCount - updatedCount),
        earliestDate: importedEntries.map(\.date).min(),
        latestDate: importedEntries.map(\.date).max()
      )
    } catch {
      let message = userFacingMessage(for: error, fallback: "백업 파일을 확인하지 못했어요.")
      syncStatus = .failed("백업 미리보기 실패: \(message)")
      return nil
    }
  }

  func importBackup(from url: URL, backupPassword: String? = nil) {
    do {
      let importedEntries = try loadBackupEntries(from: url, backupPassword: backupPassword)
      mergeImportedEntries(importedEntries)
      syncStatus = .synced(Date())
    } catch {
      let message = userFacingMessage(for: error, fallback: "백업 파일을 가져오지 못했어요.")
      syncStatus = .failed("백업 가져오기 실패: \(message)")
    }
  }

  private func loadBackupEntries(from url: URL, backupPassword: String?) throws -> [MoodEntry] {
    let didAccess = url.startAccessingSecurityScopedResource()
    defer {
      if didAccess { url.stopAccessingSecurityScopedResource() }
    }

    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
    if let fileSize = resourceValues.fileSize, fileSize > maxBackupImportBytes {
      throw BackupImportError.fileTooLarge
    }

    let ext = url.pathExtension.lowercased()
    guard ["csv", "json", "txt", "moodieskybackup"].contains(ext) else {
      throw BackupImportError.unsupportedFormat
    }

    let data = try Data(contentsOf: url)
    guard data.count <= maxBackupImportBytes else { throw BackupImportError.fileTooLarge }

    let importedEntries: [MoodEntry]
    if ext == "csv" {
      importedEntries = try decodeCSVBackup(data)
    } else if ext == "moodieskybackup" {
      guard let backupPassword, !backupPassword.isEmpty else { throw BackupImportError.passwordRequired }
      let decryptedData = try decryptBackupData(data, password: backupPassword)
      importedEntries = try decodeJSONBackup(decryptedData)
    } else {
      importedEntries = try decodeJSONBackup(data)
    }
    return try sanitizedImportedEntries(importedEntries)
  }

  private func decryptBackupData(_ data: Data, password: String) throws -> Data {
    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let payload = try decoder.decode(EncryptedBackupPayload.self, from: data)
      let key = backupEncryptionKey(password: password, salt: payload.salt)
      let sealedBox = try AES.GCM.SealedBox(combined: payload.sealedData)
      return try AES.GCM.open(sealedBox, using: key)
    } catch {
      throw BackupImportError.invalidBackupPassword
    }
  }

  private func backupEncryptionKey(password: String, salt: Data) -> SymmetricKey {
    HKDF<SHA256>.deriveKey(
      inputKeyMaterial: SymmetricKey(data: Data(password.utf8)),
      salt: salt,
      info: Data("MoodieSkyBackupEncryption".utf8),
      outputByteCount: 32
    )
  }

  private func decodeJSONBackup(_ data: Data) throws -> [MoodEntry] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    if let payload = try? decoder.decode(MoodBackupPayload.self, from: data) {
      return payload.entries
    }
    return try decoder.decode([MoodEntry].self, from: data)
  }

  private func decodeCSVBackup(_ data: Data) throws -> [MoodEntry] {
    guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
      throw BackupImportError.invalidEncoding
    }
    let rows = parseCSV(text)
    guard let header = rows.first else { throw BackupImportError.missingRequiredFields }
    let index = Dictionary(uniqueKeysWithValues: header.enumerated().map { ($0.element, $0.offset) })
    guard index["id"] != nil, index["date"] != nil else {
      throw BackupImportError.missingRequiredFields
    }
    guard rows.count - 1 <= maxBackupImportEntries else { throw BackupImportError.tooManyEntries }
    let formatter = ISO8601DateFormatter()

    return rows.dropFirst().compactMap { row in
      guard
        let idIndex = index["id"], row.indices.contains(idIndex),
        let dateIndex = index["date"], row.indices.contains(dateIndex),
        let id = UUID(uuidString: row[idIndex]),
        let date = formatter.date(from: row[dateIndex])
      else { return nil }
      let weather = value(in: row, at: index["weather"]) ?? "맑음"
      let emoji = value(in: row, at: index["emoji"]) ?? (weathers.first { $0.0 == weather }?.1 ?? "☀️")
      let note = value(in: row, at: index["note"]) ?? ""
      let intensity = Int(value(in: row, at: index["intensity"]) ?? "3") ?? 3
      let updatedAt = formatter.date(from: value(in: row, at: index["updatedAt"]) ?? "") ?? date
      let cloudRecordName = value(in: row, at: index["cloudRecordName"])
      return MoodEntry(
        id: id,
        date: date,
        weather: weather,
        emoji: emoji,
        note: note,
        intensity: intensity,
        updatedAt: updatedAt,
        needsSync: true,
        cloudRecordName: cloudRecordName?.isEmpty == true ? nil : cloudRecordName
      )
    }
  }

  private func sanitizedImportedEntries(_ importedEntries: [MoodEntry]) throws -> [MoodEntry] {
    guard importedEntries.count <= maxBackupImportEntries else { throw BackupImportError.tooManyEntries }

    let latestAllowedDate = Date().addingTimeInterval(24 * 60 * 60)
    return try importedEntries.map { entry in
      guard entry.date >= earliestAllowedBackupDate, entry.date <= latestAllowedDate,
        entry.updatedAt >= earliestAllowedBackupDate, entry.updatedAt <= latestAllowedDate
      else { throw BackupImportError.dateOutOfRange }
      let weather = weathers.contains { $0.0 == entry.weather } ? entry.weather : "맑음"
      let emoji = weathers.first { $0.0 == weather }?.1 ?? Self.emoji(for: weather)
      let trimmedNote = String(entry.note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxImportedNoteCharacters))
      return MoodEntry(
        id: entry.id,
        date: entry.date,
        weather: weather,
        emoji: emoji,
        note: trimmedNote,
        intensity: min(max(entry.intensity, 1), 5),
        updatedAt: entry.updatedAt,
        needsSync: true,
        cloudRecordName: nil
      )
    }
  }

  private func cleanupBackupExport(at url: URL?) {
    guard let url, url.path.hasPrefix(FileManager.default.temporaryDirectory.path) else { return }
    try? FileManager.default.removeItem(at: url)
  }

  func cleanupBackupExportFile(at url: URL?) {
    cleanupBackupExport(at: url)
  }

  private func value(in row: [String], at index: Int?) -> String? {
    guard let index, row.indices.contains(index) else { return nil }
    return row[index]
  }

  private func parseCSV(_ text: String) -> [[String]] {
    var rows: [[String]] = []
    var row: [String] = []
    var field = ""
    var isQuoted = false
    var iterator = Array(text.replacingOccurrences(of: "\u{FEFF}", with: "")).makeIterator()

    while let char = iterator.next() {
      if isQuoted {
        if char == "\"" {
          if let next = iterator.next() {
            if next == "\"" {
              field.append(next)
            } else {
              isQuoted = false
              if next == "," {
                row.append(field)
                field = ""
              } else if next == "\n" {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
              } else if next != "\r" {
                field.append(next)
              }
            }
          } else {
            isQuoted = false
          }
        } else {
          field.append(char)
        }
      } else if char == "\"" {
        isQuoted = true
      } else if char == "," {
        row.append(field)
        field = ""
      } else if char == "\n" {
        row.append(field)
        rows.append(row)
        row = []
        field = ""
      } else if char != "\r" {
        field.append(char)
      }
    }
    if !field.isEmpty || !row.isEmpty {
      row.append(field)
      rows.append(row)
    }
    return rows
  }

  private func mergeImportedEntries(_ importedEntries: [MoodEntry]) {
    guard !importedEntries.isEmpty else { return }
    var byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    for imported in importedEntries {
      if let existing = byID[imported.id] {
        if imported.updatedAt >= existing.updatedAt {
          existing.date = imported.date
          existing.weather = imported.weather
          existing.emoji = imported.emoji
          existing.note = imported.note
          existing.intensity = imported.intensity
          existing.updatedAt = imported.updatedAt
          existing.needsSync = true
          existing.cloudRecordName = imported.cloudRecordName
        }
      } else {
        imported.needsSync = true
        entries.append(imported)
        byID[imported.id] = imported
        modelContext?.insert(imported)
      }
    }
    entries.sort { $0.date > $1.date }
    saveEntries(reconcileBeforeSave: true)
    if isReminderEnabled { scheduleDailyReminder() }
  }

  func deleteEntries(in range: DateInterval) {
    let targets = entries.filter { range.contains($0.date) }
    guard !targets.isEmpty else { return }
    pendingDeleteIDs.append(contentsOf: targets.map(\.id))
    targets.forEach { modelContext?.delete($0) }
    entries.removeAll { entry in targets.contains { $0.id == entry.id } }
    saveEntries()
    savePendingDeleteIDs()
    if isReminderEnabled { scheduleDailyReminder() }
    syncWithICloud()
  }

  private func verifyPasscode(_ passcode: String) -> Bool {
    guard let storedHash = Self.keychainString(account: Self.passcodeHashAccount),
      let salt = Self.keychainString(account: Self.passcodeSaltAccount)
    else { return false }
    return hashPasscode(passcode, salt: salt) == storedHash
  }

  private func verifyRecoveryKey(_ recoveryKey: String) -> Bool {
    guard let storedHash = Self.keychainString(account: Self.recoveryKeyHashAccount),
      let salt = Self.keychainString(account: Self.recoveryKeySaltAccount)
    else {
      authErrorMessage = "저장된 복구키가 없어요. 기록 삭제 후 초기화가 필요해요."
      return false
    }
    guard hashRecoveryKey(recoveryKey, salt: salt) == storedHash else {
      authErrorMessage = "복구키가 맞지 않아요."
      return false
    }
    return true
  }

  private static func migrateLegacyPasscodeIfNeeded(defaults: UserDefaults) {
    guard keychainString(account: passcodeHashAccount) == nil,
      let legacyHash = defaults.string(forKey: "moodie_passcode_hash"),
      let legacySalt = defaults.string(forKey: "moodie_passcode_salt")
    else { return }

    if setKeychainString(legacyHash, account: passcodeHashAccount),
      setKeychainString(legacySalt, account: passcodeSaltAccount)
    {
      defaults.removeObject(forKey: "moodie_passcode_hash")
      defaults.removeObject(forKey: "moodie_passcode_salt")
    }
  }

  private static func keychainString(account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: passcodeKeychainService,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static func setKeychainString(_ value: String, account: String) -> Bool {
    let data = Data(value.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: passcodeKeychainService,
      kSecAttrAccount as String: account,
    ]
    let attributes: [String: Any] = [kSecValueData as String: data]

    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecSuccess { return true }
    guard updateStatus == errSecItemNotFound else { return false }

    let addQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: passcodeKeychainService,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      kSecValueData as String: data,
    ]
    return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
  }

  private static func deleteKeychainItem(account: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: passcodeKeychainService,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
  }

  private func hashPasscode(_ passcode: String, salt: String) -> String {
    let data = Data("\(salt):\(passcode)".utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private func makeRecoveryKey() -> String {
    let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    let characters = (0..<20).map { _ in String(alphabet[Int.random(in: 0..<alphabet.count)]) }
    return stride(from: 0, to: characters.count, by: 4)
      .map { characters[$0..<min($0 + 4, characters.count)].joined() }
      .joined(separator: "-")
  }

  private func hashRecoveryKey(_ recoveryKey: String, salt: String) -> String {
    hashPasscode(normalizedRecoveryKey(recoveryKey), salt: salt)
  }

  private func normalizedRecoveryKey(_ recoveryKey: String) -> String {
    recoveryKey
      .uppercased()
      .filter { $0.isLetter || $0.isNumber }
  }

  private func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?
    let reason = "Moodie Sky 앱 암호를 빠르게 해제해요."

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      authErrorMessage = "이 기기에서는 Face ID를 사용할 수 없어요."
      completion(false)
      return
    }

    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
      [weak self] success, error in
      DispatchQueue.main.async {
        if let error, !success {
          self?.authErrorMessage = self?.biometricMessage(for: error) ?? "Face ID 인증을 완료하지 못했어요."
        } else if success {
          self?.authErrorMessage = ""
        }
        completion(success)
      }
    }
  }

  private func biometricMessage(for error: Error) -> String {
    guard let laError = error as? LAError else {
      return "Face ID 인증을 완료하지 못했어요."
    }

    switch laError.code {
    case .userCancel, .systemCancel, .appCancel:
      return ""
    case .userFallback:
      return "앱 암호로 인증해주세요."
    case .biometryLockout:
      return "Face ID가 잠시 잠겼어요. 기기 암호로 잠금을 해제한 뒤 다시 시도해주세요."
    case .biometryNotAvailable:
      return "이 기기에서는 Face ID를 사용할 수 없어요."
    case .biometryNotEnrolled:
      return "설정 앱에서 Face ID를 먼저 등록해주세요."
    default:
      return "Face ID 인증을 완료하지 못했어요."
    }
  }

  // MARK: - 영구 저장
  func saveEntries(reconcileBeforeSave: Bool = false) {
    guard let modelContext else { return }
    if reconcileBeforeSave {
      persistCurrentEntries(in: modelContext)
    }
    do {
      try modelContext.save()
    } catch {
      syncStatus = .failed("저장하지 못했어요. 잠시 후 다시 시도해주세요.")
    }
  }

  func loadEntries() {
    guard let modelContext else { return }
    var descriptor = FetchDescriptor<MoodEntry>(
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.includePendingChanges = true
    do {
      entries = try modelContext.fetch(descriptor)
    } catch {
      syncStatus = .failed("기록을 불러오지 못했어요. 앱을 다시 열어 확인해주세요.")
    }
  }

  private func migrateLegacyEntriesIfNeeded() {
    guard let modelContext,
      !UserDefaults.standard.bool(forKey: swiftDataMigrationKey)
    else { return }

    let legacyEntries = loadLegacyUserDefaultsEntries()
    guard !legacyEntries.isEmpty else {
      UserDefaults.standard.set(true, forKey: swiftDataMigrationKey)
      return
    }

    do {
      let storedEntries = try modelContext.fetch(FetchDescriptor<MoodEntry>())
      let storedIDs = Set(storedEntries.map(\.id))
      for entry in legacyEntries where !storedIDs.contains(entry.id) {
        modelContext.insert(entry)
      }
      try modelContext.save()
      UserDefaults.standard.set(true, forKey: swiftDataMigrationKey)
    } catch {
      syncStatus = .failed("기존 기록을 이전하지 못했어요. 앱을 다시 열어 확인해주세요.")
    }
  }

  private func loadLegacyUserDefaultsEntries() -> [MoodEntry] {
    let defaults = UserDefaults.standard
    let primaryEntries = decodeLegacyEntries(from: defaults.data(forKey: "mood_data"))
    if !primaryEntries.isEmpty { return primaryEntries }
    return decodeLegacyEntries(from: defaults.data(forKey: "moodEntries"))
  }

  private func decodeLegacyEntries(from data: Data?) -> [MoodEntry] {
    guard let data else { return [] }
    return (try? JSONDecoder().decode([MoodEntry].self, from: data)) ?? []
  }

  private func persistCurrentEntries(in modelContext: ModelContext) {
    let storedEntries = (try? modelContext.fetch(FetchDescriptor<MoodEntry>())) ?? []
    var storedByID = Dictionary(uniqueKeysWithValues: storedEntries.map { ($0.id, $0) })
    let currentIDs = Set(entries.map(\.id))

    for storedEntry in storedEntries where !currentIDs.contains(storedEntry.id) {
      modelContext.delete(storedEntry)
    }

    for entry in entries {
      if let storedEntry = storedByID[entry.id], storedEntry !== entry {
        storedEntry.date = entry.date
        storedEntry.weather = entry.weather
        storedEntry.emoji = entry.emoji
        storedEntry.note = entry.note
        storedEntry.updatedAt = entry.updatedAt
        storedEntry.needsSync = entry.needsSync
        storedEntry.cloudRecordName = entry.cloudRecordName
      } else if storedByID[entry.id] == nil {
        modelContext.insert(entry)
        storedByID[entry.id] = entry
      }
    }
  }

  func savePendingDeleteIDs() {
    UserDefaults.standard.set(
      pendingDeleteIDs.map { $0.uuidString },
      forKey: pendingDeleteIDsKey
    )
  }

  func loadPendingDeleteIDs() {
    let values = UserDefaults.standard.stringArray(forKey: pendingDeleteIDsKey) ?? []
    pendingDeleteIDs = values.compactMap { UUID(uuidString: $0) }
  }

  // MARK: - iCloud 동기화
  // 현재는 폰 설치용 버전이라 비활성화 상태입니다.
  // 나중에 실제 동기화를 켤 때는 아래 #if 블록 안의 코드를 활성화하세요.
  func syncWithICloud() {
    #if ENABLE_ICLOUD_SYNC
      Task {
        syncStatus = .syncing
        do {
          let result = try await CloudSyncManager.shared.sync(
            entries: entries,
            pendingDeleteIDs: pendingDeleteIDs
          )
          entries = result.entries
          pendingDeleteIDs = result.pendingDeleteIDs
          saveEntries(reconcileBeforeSave: true)
          savePendingDeleteIDs()
          syncStatus = .synced(Date())
        } catch {
          syncStatus = .failed("동기화를 완료하지 못했어요. 네트워크 상태를 확인해주세요.")
        }
      }
    #else
      return
    #endif
  }
}
