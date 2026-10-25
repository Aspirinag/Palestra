import SwiftUI
import UserNotifications

// Tiene i dati dell'app e li salva in un file JSON a ogni modifica
@Observable
final class Archivio {
    var stato: Stato {
        didSet { if !demo { salva() } }
    }

    let demo: Bool

    init() {
        demo = Avvio.demo
        stato = demo ? Stato.demo : Self.carica()
    }

    // ---------- File ----------

    private static var fileDati: URL {
        URL.applicationSupportDirectory.appending(path: "palestra.json")
    }

    // Ordine: file dell'app, poi i dati della prima versione dell'app (Capacitor), poi i valori iniziali
    private static func carica() -> Stato {
        if let d = try? Data(contentsOf: fileDati), let s = try? JSONDecoder().decode(Stato.self, from: d) {
            return s
        }
        if let j = UserDefaults.standard.string(forKey: "CapacitorStorage.palestra:v2"),
           let s = try? JSONDecoder().decode(Stato.self, from: Data(j.utf8)) {
            return s
        }
        return Stato()
    }

    private func salva() {
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try backup().write(to: Self.fileDati, options: .atomic)
        } catch {
            print("Salvataggio non riuscito: \(error)")
        }
    }

    func backup() -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? e.encode(stato)) ?? Data()
    }

    func importa(_ dati: Data) throws {
        stato = try JSONDecoder().decode(Stato.self, from: dati)
    }

    // ---------- Settimane A/B ----------

    // Numero progressivo della settimana, contato dal lunedì 29/12/2025 (settimana 1 del 2026)
    // senza ripartire a gennaio: così A e B si alternano anche dopo un anno di 53 settimane
    static func numeroSettimana(_ iso: String) -> Int {
        let inizio = Giorni.data("2025-12-29")
        let giorni = Giorni.calendario.dateComponents([.day], from: inizio, to: Giorni.data(iso)).day ?? 0
        return Int((Double(giorni) / 7).rounded(.down)) + 1
    }

    func settimana(_ iso: String) -> String {
        (Self.numeroSettimana(iso) + (stato.swap ? 1 : 0)) % 2 == 0 ? "A" : "B"
    }

    func programmato(_ iso: String) -> TipoGiorno {
        TipoGiorno(rawValue: stato.plans[settimana(iso)]?[Giorni.indice(iso)] ?? "") ?? .riposo
    }

    // Allenamento di oggi, altrimenti il prossimo
    func prossimoAllenamento() -> TipoGiorno {
        let oggi = Giorni.oggi()
        for i in 0...7 {
            let t = programmato(Giorni.aggiungi(oggi, i))
            if t != .riposo { return t }
        }
        return .pesi
    }

    // ---------- Pesi ----------

    func ultimaSerie(_ esercizio: String, esclusoOggi: Bool = false) -> Serie? {
        let oggi = Giorni.oggi()
        return stato.sets.last { $0.exercise == esercizio && (!esclusoOggi || $0.date != oggi) }
    }

    func serieDiOggi(_ esercizio: String) -> [Serie] {
        let oggi = Giorni.oggi()
        return stato.sets.filter { $0.exercise == esercizio && $0.date == oggi }
    }

    // Carico di avvicinamento: percentuale dell'ultimo carico, arrotondata ai 2,5 kg dei dischi
    func avvicinamento(_ esercizio: String, _ percentuale: Double) -> String {
        guard let kg = ultimaSerie(esercizio)?.kg else { return "\(Int(percentuale * 100))% del carico di lavoro" }
        return "\(num((kg * percentuale / 2.5).rounded() * 2.5)) kg"
    }

    // Carico massimo per giornata (ultime 12 giornate)
    func progressi(_ esercizio: String) -> [(data: Date, kg: Double)] {
        var perGiorno: [String: Double] = [:]
        for s in stato.sets where s.exercise == esercizio { perGiorno[s.date] = max(perGiorno[s.date] ?? 0, s.kg) }
        return perGiorno.keys.sorted().suffix(12).map { (data: Giorni.data($0), kg: perGiorno[$0] ?? 0) }
    }

    func salvaSerie(_ esercizio: String, kg: Double, reps: Int) {
        stato.sets.append(Serie(date: Giorni.oggi(), exercise: esercizio, kg: kg, reps: reps))
        segnaFatto(.pesi)
    }

    func salvaCardio(tipo: String, minuti: Int, km: Double) {
        stato.cardio.insert(Sessione(date: Giorni.oggi(), type: tipo, minutes: minuti, km: km), at: 0)
        segnaFatto(.cardio)
    }

    // Salvare una serie o una sessione segna oggi come fatto nel calendario (se non era già segnato)
    private func segnaFatto(_ tipo: Esito) {
        let oggi = Giorni.oggi()
        if stato.log[oggi] == nil || stato.log[oggi] == Esito.saltato.rawValue { stato.log[oggi] = tipo.rawValue }
    }

    // ---------- Checklist di oggi ----------

    func spuntato(_ chiave: String) -> Bool { stato.checks[Giorni.oggi()]?[chiave] == true }

    func spunta(_ chiave: String) {
        let oggi = Giorni.oggi()
        stato.checks[oggi, default: [:]][chiave] = !spuntato(chiave)
    }

    // ---------- Pagamento ----------

    static func mese(_ iso: String) -> String { String(iso.prefix(7)) }

    // Mese da pagare e testo del promemoria, dal 25 al 2 del mese finché non è segnato pagato
    func promemoriaPagamento() -> (mese: String, testo: String)? {
        let oggi = Giorni.oggi()
        let giorno = Giorni.calendario.component(.day, from: Date())
        if giorno > 2 && giorno < 25 { return nil }
        var mese = Self.mese(oggi)
        var testo = "Oggi si paga la palestra (1 o 2 del mese)."
        if giorno >= 25 {
            let primo = Giorni.calendario.date(byAdding: .month, value: 1, to: Giorni.data(String(oggi.prefix(8)) + "01")) ?? Date()
            mese = Self.mese(Giorni.iso(primo))
            let mancano = Giorni.calendario.dateComponents([.day], from: Giorni.data(oggi), to: primo).day ?? 0
            testo = mancano == 1 ? "Domani si paga la palestra (1 o 2 del mese)." : "Tra \(mancano) giorni si paga la palestra (1 o 2 del mese)."
        }
        return stato.payments[mese] == nil ? (mese, testo) : nil
    }

    func segnaPagato(_ mese: String) {
        stato.payments[mese] = Giorni.oggi()
        Task { await programmaPagamento() }
    }

    func annullaPagamento(_ mese: String) {
        stato.payments[mese] = nil
        Task { await programmaPagamento() }
    }

    // Una sola notifica, il primo giorno utile (1 o 2 alle 9:00) di un mese non ancora pagato
    func programmaPagamento() async {
        guard !demo else { return }
        let centro = UNUserNotificationCenter.current()
        centro.removePendingNotificationRequests(withIdentifiers: ["pagamento"])
        let ora = Date()
        let questoMese = Giorni.data(String(Giorni.oggi().prefix(8)) + "01")
        for m in 0..<3 {
            guard let mese = Giorni.calendario.date(byAdding: .month, value: m, to: questoMese) else { continue }
            if stato.payments[Self.mese(Giorni.iso(mese))] != nil { continue }
            for giorno in [1, 2] {
                var dc = Giorni.calendario.dateComponents([.year, .month], from: mese)
                dc.day = giorno
                dc.hour = 9
                guard let quando = Giorni.calendario.date(from: dc), quando > ora else { continue }
                let c = UNMutableNotificationContent()
                c.title = "Palestra"
                c.body = giorno == 1 ? "Oggi si paga la palestra (1 o 2 del mese)." : "Ultimo giorno per pagare la palestra."
                c.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
                try? await centro.add(UNNotificationRequest(identifier: "pagamento", content: c, trigger: trigger))
                return
            }
        }
    }
}

enum Notifiche {
    static func permesso() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}

// Mostra le notifiche anche con l'app aperta
final class DelegatoNotifiche: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
