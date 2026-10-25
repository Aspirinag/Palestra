import SwiftUI

// Date come nella web app: stringhe yyyy-MM-dd nel fuso del telefono, settimana da lunedì
enum Giorni {
    static let nomi = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]

    static let calendario: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "it_IT")
        c.firstWeekday = 2
        return c
    }()

    static func iso(_ data: Date) -> String {
        let c = calendario.dateComponents([.year, .month, .day], from: data)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func data(_ iso: String) -> Date {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return Date() }
        return calendario.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) ?? Date()
    }

    static func oggi() -> String { iso(Date()) }

    static func aggiungi(_ iso: String, _ giorni: Int) -> String {
        Self.iso(calendario.date(byAdding: .day, value: giorni, to: data(iso)) ?? Date())
    }

    // Lunedì = 0 … Domenica = 6
    static func indice(_ iso: String) -> Int {
        (calendario.component(.weekday, from: data(iso)) + 5) % 7
    }

    static func lunedi(_ iso: String) -> String { aggiungi(iso, -indice(iso)) }

    // gg/mm/aaaa
    static func breve(_ iso: String) -> String {
        let p = iso.split(separator: "-")
        guard p.count == 3 else { return iso }
        return "\(p[2])/\(p[1])/\(p[0])"
    }
}

// Numeri all'italiana, senza decimali inutili: 81,1 · 80 · 0,25
func num(_ v: Double?) -> String {
    guard let v else { return "–" }
    let arrotondato = (v * 100).rounded() / 100
    if arrotondato == arrotondato.rounded() { return String(Int(arrotondato)) }
    return String(arrotondato).replacingOccurrences(of: ".", with: ",")
}

// Legge un numero scritto con la virgola o con il punto
func leggiNumero(_ testo: String) -> Double? {
    Double(testo.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
}

// Argomenti di avvio usati per le schermate di prova nel simulatore (es. -tab andamento -demo)
enum Avvio {
    static let argomenti = ProcessInfo.processInfo.arguments
    static var demo: Bool { argomenti.contains("-demo") }

    static func valore(_ chiave: String) -> String? {
        guard let i = argomenti.firstIndex(of: chiave), i + 1 < argomenti.count else { return nil }
        return argomenti[i + 1]
    }
}

extension View {
    // Pulsanti Liquid Glass su iOS 26, pulsanti classici sulle versioni precedenti
    @ViewBuilder
    func pulsanteVetro(evidente: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if evidente { buttonStyle(.glassProminent) } else { buttonStyle(.glass) }
        } else {
            if evidente { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        }
    }
}

// Voce di una checklist: cerchio pieno quando è fatta
struct RigaSpunta<Etichetta: View>: View {
    let fatto: Bool
    let azione: () -> Void
    @ViewBuilder let etichetta: Etichetta

    var body: some View {
        Button(action: azione) {
            HStack(spacing: 12) {
                Image(systemName: fatto ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(fatto ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .contentTransition(.symbolEffect(.replace))
                etichetta
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: fatto)
    }
}
