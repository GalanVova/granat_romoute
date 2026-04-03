import Foundation

// MARK: - Schedule rule

struct ScheduleRule: Identifiable, Codable {
    var id: String = UUID().uuidString
    var action: ScheduleAction
    var hour: Int
    var minute: Int
    var days: Set<Weekday>
    var panelGroupId: String? // nil = all panels

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

enum ScheduleAction: String, Codable, CaseIterable {
    case arm      = "arm"
    case disarm   = "disarm"
    case armStay  = "arm_stay"
}

enum Weekday: Int, Codable, CaseIterable, Hashable {
    case mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7, sun = 1

    var shortKey: String {
        switch self {
        case .mon: return "schedule.mon"
        case .tue: return "schedule.tue"
        case .wed: return "schedule.wed"
        case .thu: return "schedule.thu"
        case .fri: return "schedule.fri"
        case .sat: return "schedule.sat"
        case .sun: return "schedule.sun"
        }
    }

    static var weekdays: Set<Weekday> { [.mon, .tue, .wed, .thu, .fri] }
    static var weekends: Set<Weekday> { [.sat, .sun] }
    static var everyday: Set<Weekday> { Set(allCases) }

    /// Calendar weekday index (1 = Sun, 2 = Mon, ...)
    var calendarValue: Int { rawValue }
}

// MARK: - Store

class ScheduleStore: ObservableObject {
    static let shared = ScheduleStore()

    @Published var rules: [ScheduleRule] = []
    private let key = "schedule_rules_v1"

    init() { load() }

    func add(_ rule: ScheduleRule) {
        rules.append(rule)
        save()
        syncBackground()
    }

    func update(_ rule: ScheduleRule) {
        guard let i = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[i] = rule
        save()
        syncBackground()
    }

    func delete(id: String) {
        rules.removeAll { $0.id == id }
        save()
        syncBackground()
    }

    /// Re-schedules the BGProcessingTask for the next upcoming rule.
    private func syncBackground() {
        BackgroundScheduleRunner.shared.scheduleNextIfNeeded()
    }

    private func save() {
        if let d = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let r = try? JSONDecoder().decode([ScheduleRule].self, from: d) else { return }
        rules = r
    }
}
