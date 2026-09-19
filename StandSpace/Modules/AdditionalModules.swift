import SwiftUI
import Combine
import EventKit
import UIKit

struct TimerModuleView: View {
    let size: ModuleSize
    let storageID: UUID

    @State private var remainingSeconds: Int
    @State private var isRunning: Bool
    @State private var endDate: Date?

    private let defaultDuration = 25 * 60
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(size: ModuleSize, storageID: UUID) {
        self.size = size
        self.storageID = storageID

        let defaults = UserDefaults.standard
        let prefix = Self.storagePrefix(for: storageID)
        let savedRemaining = (defaults.object(forKey: prefix + "remaining") as? NSNumber)?.intValue ?? 25 * 60
        let savedRunning = defaults.bool(forKey: prefix + "running")
        let savedEndDate = defaults.object(forKey: prefix + "endDate") as? Date

        if savedRunning, let savedEndDate {
            let remaining = max(0, Int(ceil(savedEndDate.timeIntervalSinceNow)))
            _remainingSeconds = State(initialValue: remaining)
            _isRunning = State(initialValue: remaining > 0)
            _endDate = State(initialValue: remaining > 0 ? savedEndDate : nil)
        } else {
            _remainingSeconds = State(initialValue: max(0, savedRemaining))
            _isRunning = State(initialValue: false)
            _endDate = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "timer")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("25 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(timeText)
                .font(.system(size: size == .small ? 28 : 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)

            if size != .small {
                HStack(spacing: 10) {
                    Button {
                        toggleRunning()
                    } label: {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            synchronizeWithClock()
        }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            synchronizeWithClock()
        }
    }

    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func toggleRunning() {
        if isRunning {
            synchronizeWithClock()
            isRunning = false
            endDate = nil
        } else {
            if remainingSeconds <= 0 {
                remainingSeconds = defaultDuration
            }
            isRunning = true
            endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        }
        persist()
    }

    private func reset() {
        isRunning = false
        endDate = nil
        remainingSeconds = defaultDuration
        persist()
    }

    private func synchronizeWithClock() {
        guard isRunning, let endDate else { return }
        remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        if remainingSeconds == 0 {
            isRunning = false
            self.endDate = nil
            persist()
        }
    }

    private func persist() {
        let defaults = UserDefaults.standard
        let prefix = Self.storagePrefix(for: storageID)
        defaults.set(remainingSeconds, forKey: prefix + "remaining")
        defaults.set(isRunning, forKey: prefix + "running")
        if let endDate {
            defaults.set(endDate, forKey: prefix + "endDate")
        } else {
            defaults.removeObject(forKey: prefix + "endDate")
        }
    }

    private static func storagePrefix(for id: UUID) -> String {
        "standspace.timer.\(id.uuidString)."
    }
}

struct CalendarModuleView: View {
    let size: ModuleSize

    private enum DisplayState {
        case prompt
        case denied
        case unavailable(String)
        case event(String, Date)
        case empty
    }

    @State private var displayState: DisplayState = .prompt
    @State private var hasAccess = false
    @State private var isRequesting = false

    private let eventStore = EKEventStore()
    private var language: StandSpaceAppLanguage { .current }

    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3.weight(.semibold))
                Spacer()
                if hasAccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Text(displayTitle)
                .font(size == .wide ? .headline : .title2.weight(.semibold))
                .lineLimit(2)

            Text(displaySubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(size.span.rows > 1 ? 3 : 1)

            if !hasAccess {
                Button(
                    isRequesting
                        ? t("Requesting…", "Solicitando…")
                        : t("Allow Calendar", "Permitir calendario")
                ) {
                    requestAccess()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
                .disabled(isRequesting)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear {
            refreshAuthorization()
        }
    }

    private var displayTitle: String {
        switch displayState {
        case .prompt:
            return t("Calendar", "Calendario")
        case .denied:
            return t("No Access", "Sin acceso")
        case .unavailable:
            return t("Calendar Unavailable", "Calendario no disponible")
        case .event(let title, _):
            return title
        case .empty:
            return t("No Upcoming Events", "Sin eventos próximos")
        }
    }

    private var displaySubtitle: String {
        switch displayState {
        case .prompt:
            return t(
                "Tap to show your next event",
                "Toca para mostrar tu próximo evento"
            )
        case .denied:
            return t(
                "You can enable Calendar in Settings.",
                "Puedes habilitar Calendario desde Ajustes."
            )
        case .unavailable(let detail):
            return detail
        case .event(_, let startDate):
            return startDate.formatted(
                .dateTime
                    .month(.abbreviated)
                    .day()
                    .hour()
                    .minute()
                    .locale(language.locale)
            )
        case .empty:
            return t(
                "Your calendar is clear for now.",
                "Tu calendario está libre por ahora."
            )
        }
    }

    private func refreshAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess || status == .authorized {
            hasAccess = true
            loadNextEvent()
        } else {
            hasAccess = false
            displayState = .prompt
        }
    }

    private func requestAccess() {
        isRequesting = true

        Task {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    isRequesting = false
                    hasAccess = granted
                    if granted {
                        loadNextEvent()
                    } else {
                        displayState = .denied
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    displayState = .unavailable(error.localizedDescription)
                }
            }
        }
    }

    private func loadNextEvent() {
        let start = Date()
        let end = Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: start
        ) ?? start
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        if let event = eventStore.events(matching: predicate)
            .filter({ !$0.isAllDay || $0.endDate >= start })
            .sorted(by: { $0.startDate < $1.startDate })
            .first {
            displayState = .event(
                event.title ?? t("Event", "Evento"),
                event.startDate
            )
        } else {
            displayState = .empty
        }
    }
}

struct StorageModuleView: View {
    let size: ModuleSize

    @State private var usedBytes: Int64?
    @State private var freeBytes: Int64?
    @State private var totalBytes: Int64?

    private var language: StandSpaceAppLanguage { .current }

    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(t("Storage", "Almacenamiento"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(usedText)
                .font(.system(size: size == .small ? 26 : 38, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.55)

            ProgressView(value: fractionUsed)
                .progressViewStyle(.linear)

            if size != .small {
                Text(
                    t(
                        "\(freeText) available",
                        "\(freeText) disponibles"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear(perform: refresh)
    }

    private var usedText: String {
        guard let usedBytes else {
            return t("Unavailable", "No disponible")
        }
        let formatted = ByteCountFormatter.string(
            fromByteCount: usedBytes,
            countStyle: .file
        )
        return t("\(formatted) used", "\(formatted) usados")
    }

    private var freeText: String {
        guard let freeBytes else { return "—" }
        return ByteCountFormatter.string(
            fromByteCount: freeBytes,
            countStyle: .file
        )
    }

    private var fractionUsed: Double {
        guard let usedBytes,
              let totalBytes,
              totalBytes > 0 else {
            return 0
        }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    private func refresh() {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(
                forPath: NSHomeDirectory()
            )
            let total = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
            let free = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            guard total > 0 else {
                usedBytes = nil
                freeBytes = nil
                totalBytes = nil
                return
            }

            totalBytes = total
            freeBytes = free
            usedBytes = max(total - free, 0)
        } catch {
            usedBytes = nil
            freeBytes = nil
            totalBytes = nil
        }
    }
}

struct DeviceInfoModuleView: View {
    let size: ModuleSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(UIDevice.current.systemName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(UIDevice.current.name)
                .font(.title2.weight(.semibold))
                .lineLimit(1)

            Text("\(UIDevice.current.model) · \(UIDevice.current.systemVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if size.span.rows > 1 {
                Text(
                    StandSpaceAppLanguage.current.text(
                        english: "StandSpace on this device",
                        spanish: "StandSpace en este dispositivo"
                    )
                )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct DayProgressModuleView: View {
    let size: ModuleSize

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            let progress = dayProgress(for: context.date)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: "sun.max")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Text(
                        StandSpaceAppLanguage.current.text(
                            english: "Today",
                            spanish: "Hoy"
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: size == .small ? 30 : 42, weight: .semibold, design: .rounded))

                ProgressView(value: progress)
                    .progressViewStyle(.linear)

                if size != .small {
                    Text(
                        StandSpaceAppLanguage.current.text(
                            english: "of the day elapsed",
                            spanish: "del día transcurrido"
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func dayProgress(for date: Date) -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / total, 0), 1)
    }
}
