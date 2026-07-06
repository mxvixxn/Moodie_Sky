import Foundation
import HealthKit

/// Fitie 등 다른 마음챙김 앱과 HealthKit을 통해 데이터를 주고받기 위한 매니저.
/// - 쓰기: 오늘의 마음 날씨를 State of Mind(iOS 18+)로 저장
/// - 읽기: mindfulSession(호흡·명상 시간)을 읽어서 리포트에 반영
@MainActor
final class MoodieHealthKitManager {
  static let shared = MoodieHealthKitManager()

  private let healthStore = HKHealthStore()

  private init() {}

  var isHealthDataAvailable: Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  private var mindfulSessionType: HKCategoryType? {
    HKObjectType.categoryType(forIdentifier: .mindfulSession)
  }

  // MARK: - 권한 요청

  func requestAuthorization() async -> Bool {
    guard isHealthDataAvailable, let mindfulSessionType else { return false }

    var shareTypes: Set<HKSampleType> = []
    if #available(iOS 18.0, *) {
      shareTypes.insert(HKObjectType.stateOfMindType())
    }
    let readTypes: Set<HKObjectType> = [mindfulSessionType]

    do {
      try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
      return true
    } catch {
      return false
    }
  }

  // MARK: - 마음 날씨 → State of Mind 기록

  func recordStateOfMind(weather: String, date: Date) {
    guard isHealthDataAvailable else { return }
    guard #available(iOS 18.0, *) else { return }

    let sample = HKStateOfMind(
      date: date,
      kind: .momentaryEmotion,
      valence: Self.valence(for: weather),
      labels: Self.labels(for: weather),
      associations: [.weather, .selfCare]
    )

    Task {
      try? await healthStore.save(sample)
    }
  }

  private static func valence(for weather: String) -> Double {
    switch weather {
    case "맑음": return 0.6
    case "무지개": return 0.9
    case "구름": return 0.0
    case "비": return -0.5
    case "폭풍": return -0.85
    default: return 0.0
    }
  }

  @available(iOS 18.0, *)
  private static func labels(for weather: String) -> [HKStateOfMind.Label] {
    switch weather {
    case "맑음": return [.happy, .content]
    case "무지개": return [.joyful, .grateful]
    case "구름": return [.indifferent]
    case "비": return [.sad]
    case "폭풍": return [.stressed, .anxious]
    default: return [.indifferent]
    }
  }

  // MARK: - 마음챙김 시간 읽기 (Fitie 등에서 기록한 mindfulSession)

  func fetchMindfulMinutes(from startDate: Date, to endDate: Date) async -> TimeInterval {
    guard isHealthDataAvailable, let mindfulSessionType else { return 0 }
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate, end: endDate, options: .strictStartDate)

    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: mindfulSessionType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: nil
      ) { _, samples, _ in
        let total =
          (samples as? [HKCategorySample])?.reduce(0.0) { partial, sample in
            partial + sample.endDate.timeIntervalSince(sample.startDate)
          } ?? 0
        continuation.resume(returning: total)
      }
      healthStore.execute(query)
    }
  }

  /// 마음챙김을 한 날과 하지 않은 날의 날짜(자정 기준)를 구분해서 돌려줘요.
  func mindfulDays(from startDate: Date, to endDate: Date) async -> Set<Date> {
    guard isHealthDataAvailable, let mindfulSessionType else { return [] }
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate, end: endDate, options: .strictStartDate)
    let calendar = Calendar.current

    return await withCheckedContinuation { continuation in
      let query = HKSampleQuery(
        sampleType: mindfulSessionType,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: nil
      ) { _, samples, _ in
        let days = Set(
          (samples as? [HKCategorySample] ?? []).map { calendar.startOfDay(for: $0.startDate) })
        continuation.resume(returning: days)
      }
      healthStore.execute(query)
    }
  }
}
