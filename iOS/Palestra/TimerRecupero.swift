import SwiftUI
import UserNotifications

// Timer di recupero tra le serie: a fine recupero vibra e, con l'app chiusa o il telefono bloccato,
// arriva una notifica
@Observable
final class TimerRecupero {
    private(set) var fine: Date?
    private var compito: Task<Void, Never>?
    var finiti = 0     // cambia a ogni recupero concluso (per la vibrazione)

    var attivo: Bool { fine.map { $0 > Date() } ?? false }

    func avvia(_ secondi: Int) {
        ferma()
        let f = Date().addingTimeInterval(TimeInterval(secondi))
        fine = f
        let c = UNMutableNotificationContent()
        c.title = "Recupero finito"
        c.body = "Via con la prossima serie 💪"
        c.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(secondi), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "recupero", content: c, trigger: trigger))
        compito = Task {
            try? await Task.sleep(for: .seconds(secondi))
            guard !Task.isCancelled else { return }
            // Se l'app era in background la notifica è già arrivata: niente vibrazione in ritardo
            if Date().timeIntervalSince(f) < 2 { finiti += 1 }
            fine = nil
        }
    }

    func ferma() {
        compito?.cancel()
        compito = nil
        fine = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["recupero"])
    }
}

// Barra del timer: su iOS 26 sta sopra la tab bar (accessorio Liquid Glass)
struct BarraTimer: View {
    @Environment(TimerRecupero.self) private var timer

    var body: some View {
        HStack(spacing: 10) {
            if let fine = timer.fine, timer.attivo {
                Image(systemName: "timer")
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse)
                Text(timerInterval: Date()...fine, countsDown: true)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.tint)
                Spacer()
                Button("Stop", systemImage: "stop.fill") { timer.ferma() }
                    .labelStyle(.iconOnly)
            } else {
                Label("Recupero", systemImage: "timer")
                    .foregroundStyle(.secondary)
                Spacer()
                ForEach([60, 90, 120], id: \.self) { s in
                    Button("\(s)s") { timer.avvia(s) }
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.success, trigger: timer.finiti)
    }
}
