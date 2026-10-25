import Foundation

// Dati di prova per le schermate nel simulatore (avvio con -demo): non vengono salvati
extension Stato {
    static var demo: Stato {
        var s = Stato()
        let oggi = Giorni.oggi()
        let carichi: [String: Double] = ["Leg press": 70, "Chest press": 30, "Lat machine": 35, "Leg curl": 25, "Shoulder press": 15, "Seated row": 30]
        for (n, settimana) in [-21, -14, -7, -3].enumerated() {
            let d = Giorni.aggiungi(oggi, settimana)
            for (esercizio, kg) in carichi.sorted(by: { $0.key < $1.key }) {
                for _ in 0..<3 { s.sets.append(Serie(date: d, exercise: esercizio, kg: kg + Double(n) * 2.5, reps: 10)) }
            }
            s.log[d] = "pesi"
        }
        s.sets.append(Serie(date: oggi, exercise: "Leg press", kg: 80, reps: 10))
        s.sets.append(Serie(date: oggi, exercise: "Leg press", kg: 80, reps: 9))
        s.log[oggi] = "pesi"
        for k in [-12, -9, -5, -1] {
            let d = Giorni.aggiungi(oggi, k)
            s.cardio.insert(Sessione(date: d, type: k == -5 ? "Bici" : "Corsa", minutes: 30, km: k == -5 ? 12 : 4.5), at: 0)
            s.log[d] = "cardio"
        }
        s.log[Giorni.aggiungi(oggi, -10)] = "saltato"
        s.checks[oggi] = ["pesi-w0": true, "pesi-w1": true, "pesi-r0": true]
        return s
    }
}
