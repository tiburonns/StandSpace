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

    @State private var eventTitle = "Calendario"
    @State private var eventSubtitle = "Toca para mostrar tu próximo evento"
    @State private var hasAccess = false
    @State private var isRequesting = false

    private let eventStore = EKEventStore()

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

            Text(eventTitle)
                .font(size == .wide ? .headline : .title2.weight(.semibold))
                .lineLimit(2)

            Text(eventSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(size.span.rows > 1 ? 3 : 1)

            if !hasAccess {
                Button(isRequesting ? "Solicitando…" : "Permitir calendario") {
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

    private func refreshAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess || status == .authorized {
            hasAccess = true
            loadNextEvent()
        } else {
            hasAccess = false
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
                        eventTitle = "Sin acceso"
                        eventSubtitle = "Puedes habilitar Calendario desde Ajustes."
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    eventTitle = "Calendario no disponible"
                    eventSubtitle = error.localizedDescription
                }
            }
        }
    }

    private func loadNextEvent() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)

        if let event = eventStore.events(matching: predicate)
            .filter({ !$0.isAllDay || $0.endDate >= start })
            .sorted(by: { $0.startDate < $1.startDate })
            .first {
            eventTitle = event.title ?? "Evento"
            eventSubtitle = event.startDate.formatted(date: .abbreviated, time: .shortened)
        } else {
            eventTitle = "Sin eventos próximos"
            eventSubtitle = "Tu calendario está libre por ahora."
        }
    }
}

struct StorageModuleView: View {
    let size: ModuleSize

    @State private var usedText = "—"
    @State private var freeText = "—"
    @State private var fractionUsed = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("Almacenamiento")
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
                Text("\(freeText) disponibles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
            let free = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            let used = max(total - free, 0)

            guard total > 0 else { return }

            fractionUsed = Double(used) / Double(total)
            usedText = ByteCountFormatter.string(fromByteCount: used, countStyle: .file) + " usados"
            freeText = ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
        } catch {
            usedText = "No disponible"
            freeText = "—"
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
                Text("StandSpace en este dispositivo")
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
                    Text("Hoy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: size == .small ? 30 : 42, weight: .semibold, design: .rounded))

                ProgressView(value: progress)
                    .progressViewStyle(.linear)

                if size != .small {
                    Text("del día transcurrido")
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
