#if canImport(HealthKit)
import Foundation
import HealthKit

enum HealthKitMetricsError: LocalizedError {
    case unavailable
    case unsupportedDayKey(String)
    case missingStepType
    case missingSleepType

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Health data is not available on this device."
        case .unsupportedDayKey(let dayKey):
            return "Unable to read metrics for day key \(dayKey)."
        case .missingStepType:
            return "Step count is not available from HealthKit."
        case .missingSleepType:
            return "Sleep analysis is not available from HealthKit."
        }
    }
}

final class HealthKitMetricsProvider: HealthMetricsProviding {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitMetricsError.unavailable
        }

        guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitMetricsError.missingStepType
        }

        guard let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitMetricsError.missingSleepType
        }

        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: [steps, sleep]) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func metrics(for dayKey: String) async throws -> DailyHealthMetrics {
        let interval = try dateInterval(for: dayKey)
        async let steps = stepCount(in: interval)
        async let sleepMinutes = sleepMinutes(in: interval)

        return try await DailyHealthMetrics(
            steps: steps,
            sleepMinutes: sleepMinutes
        )
    }

    private func dateInterval(for dayKey: String) throws -> DateInterval {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        guard let start = formatter.date(from: dayKey),
              let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else {
            throw HealthKitMetricsError.unsupportedDayKey(dayKey)
        }

        return DateInterval(start: start, end: end)
    }

    private func stepCount(in interval: DateInterval) async throws -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitMetricsError.missingStepType
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate])
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let count = statistics?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: count.map { Int($0.rounded()) })
            }

            healthStore.execute(query)
        }
    }

    private func sleepMinutes(in interval: DateInterval) async throws -> Int? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitMetricsError.missingSleepType
        }

        return try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [])
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let minutes = (samples as? [HKCategorySample])?
                    .filter(Self.isAsleep)
                    .reduce(0.0) { total, sample in
                        let overlapStart = max(sample.startDate, interval.start)
                        let overlapEnd = min(sample.endDate, interval.end)
                        guard overlapEnd > overlapStart else { return total }
                        return total + overlapEnd.timeIntervalSince(overlapStart) / 60
                    }

                continuation.resume(returning: minutes.map { Int($0.rounded()) })
            }

            healthStore.execute(query)
        }
    }

    private static func isAsleep(_ sample: HKCategorySample) -> Bool {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return false
        }

        switch value {
        case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
            return true
        case .inBed, .awake:
            return false
        @unknown default:
            return false
        }
    }
}
#endif
