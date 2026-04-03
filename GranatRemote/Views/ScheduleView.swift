import SwiftUI

// MARK: - Schedule list

struct ScheduleView: View {
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject var store = ScheduleStore.shared
    @State private var showAdd = false
    @State private var editing: ScheduleRule?

    private func s(_ key: String) -> String { appSettings.t(key) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(s("schedule.title"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryRed)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if store.rules.isEmpty {
                    Spacer()
                    Text(s("schedule.none"))
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(store.rules) { rule in
                                ScheduleRuleCard(rule: rule, settings: appSettings) {
                                    editing = rule
                                } onDelete: {
                                    store.delete(id: rule.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ScheduleEditSheet(settings: appSettings, existing: nil) { rule in
                store.add(rule)
                showAdd = false
            } onCancel: { showAdd = false }
        }
        .sheet(item: $editing) { rule in
            ScheduleEditSheet(settings: appSettings, existing: rule) { updated in
                store.update(updated)
                editing = nil
            } onCancel: { editing = nil }
        }
    }
}

// MARK: - Rule card

struct ScheduleRuleCard: View {
    let rule: ScheduleRule
    let settings: AppSettings
    let onEdit: () -> Void
    let onDelete: () -> Void

    private func s(_ k: String) -> String { settings.t(k) }

    private var actionLabel: String {
        switch rule.action {
        case .arm:     return s("schedule.arm")
        case .disarm:  return s("schedule.disarm")
        case .armStay: return s("schedule.arm_stay")
        }
    }

    private var actionIcon: String {
        switch rule.action {
        case .arm:     return "lock.fill"
        case .disarm:  return "lock.open.fill"
        case .armStay: return "house.fill"
        }
    }

    private var actionColor: Color {
        switch rule.action {
        case .arm:     return .primaryRed
        case .disarm:  return .selectedGreen
        case .armStay: return .orange
        }
    }

    private var daysLabel: String {
        let sorted = rule.days.sorted { $0.rawValue < $1.rawValue }
        if rule.days == Weekday.everyday { return s("schedule.everyday") }
        if rule.days == Weekday.weekdays { return s("schedule.weekdays") }
        if rule.days == Weekday.weekends { return s("schedule.weekends") }
        return sorted.map { s($0.shortKey) }.joined(separator: ", ")
    }

    var body: some View {
        HStack(spacing: 14) {
            // Time block
            VStack(alignment: .center, spacing: 2) {
                Text(rule.timeString)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                Text(daysLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)

            Divider().background(Color.inputBorder)

            // Action
            HStack(spacing: 8) {
                Image(systemName: actionIcon)
                    .font(.system(size: 15))
                    .foregroundColor(actionColor)
                Text(actionLabel)
                    .font(.system(size: 14))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.primaryRed)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Edit / Add sheet

struct ScheduleEditSheet: View {
    let settings: AppSettings
    var existing: ScheduleRule?
    let onSave: (ScheduleRule) -> Void
    let onCancel: () -> Void

    @State private var action: ScheduleAction
    @State private var time: Date
    @State private var days: Set<Weekday>

    private func s(_ k: String) -> String { settings.t(k) }

    init(settings: AppSettings, existing: ScheduleRule?,
         onSave: @escaping (ScheduleRule) -> Void,
         onCancel: @escaping () -> Void) {
        self.settings  = settings
        self.existing  = existing
        self.onSave    = onSave
        self.onCancel  = onCancel

        var cal = Calendar.current
        cal.timeZone = .current
        let now = Date()
        let comps: DateComponents

        if let r = existing {
            comps = DateComponents(hour: r.hour, minute: r.minute)
            _action = State(initialValue: r.action)
            _days   = State(initialValue: r.days)
        } else {
            comps = DateComponents(hour: 8, minute: 0)
            _action = State(initialValue: .arm)
            _days   = State(initialValue: Weekday.everyday)
        }
        _time = State(initialValue: cal.date(bySettingHour: comps.hour ?? 8,
                                             minute: comps.minute ?? 0,
                                             second: 0, of: now) ?? now)
    }

    private let allWeekdays = Weekday.allCases

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Form {
                    // Action
                    Section(s("schedule.action")) {
                        ForEach(ScheduleAction.allCases, id: \.self) { act in
                            Button {
                                action = act
                            } label: {
                                HStack {
                                    Text(actionLabel(act))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    if action == act {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.primaryRed)
                                    }
                                }
                            }
                        }
                    }

                    // Time
                    Section(s("schedule.time")) {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }

                    // Days
                    Section(s("schedule.days")) {
                        // Quick presets
                        HStack(spacing: 8) {
                            presetChip(s("schedule.everyday"), set: Weekday.everyday)
                            presetChip(s("schedule.weekdays"), set: Weekday.weekdays)
                            presetChip(s("schedule.weekends"), set: Weekday.weekends)
                        }
                        .padding(.vertical, 2)

                        // Individual days
                        HStack(spacing: 6) {
                            ForEach(allWeekdays, id: \.self) { day in
                                dayChip(day)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle(existing == nil ? s("schedule.add_title") : s("schedule.edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(s("btn.cancel"), action: onCancel).foregroundColor(.primaryRed)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(s("btn.save")) {
                        let cal = Calendar.current
                        var rule = existing ?? ScheduleRule(action: action, hour: 0, minute: 0, days: days)
                        rule.action = action
                        rule.hour   = cal.component(.hour, from: time)
                        rule.minute = cal.component(.minute, from: time)
                        rule.days   = days.isEmpty ? Weekday.everyday : days
                        onSave(rule)
                    }
                    .foregroundColor(.primaryRed)
                    .disabled(days.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func actionLabel(_ act: ScheduleAction) -> String {
        switch act {
        case .arm:     return s("schedule.arm")
        case .disarm:  return s("schedule.disarm")
        case .armStay: return s("schedule.arm_stay")
        }
    }

    @ViewBuilder
    private func presetChip(_ label: String, set: Set<Weekday>) -> some View {
        let selected = days == set
        Button { days = set } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selected ? .white : .textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color.primaryRed : Color.inputBackground)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayChip(_ day: Weekday) -> some View {
        let selected = days.contains(day)
        Button {
            if selected { days.remove(day) } else { days.insert(day) }
        } label: {
            Text(settings.t(day.shortKey))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selected ? .white : .textPrimary)
                .frame(width: 36, height: 32)
                .background(selected ? Color.primaryRed : Color.inputBackground)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
