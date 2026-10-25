import Foundation

// Dati dell'app. Il formato JSON è lo stesso della web app (index.html),
// così i backup si possono importare ed esportare tra le due versioni.

struct Serie: Codable, Hashable {
    var date: String      // yyyy-MM-dd
    var exercise: String
    var kg: Double
    var reps: Int

    init(date: String, exercise: String, kg: Double, reps: Int) {
        self.date = date
        self.exercise = exercise
        self.kg = kg
        self.reps = reps
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.valore(.date, "")
        exercise = c.valore(.exercise, "")
        kg = c.valore(.kg, 0.0)
        reps = c.valore(.reps, 0)
    }
}

struct Sessione: Codable, Hashable {
    var date: String
    var type: String
    var minutes: Int
    var km: Double

    init(date: String, type: String, minutes: Int, km: Double) {
        self.date = date
        self.type = type
        self.minutes = minutes
        self.km = km
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.valore(.date, "")
        type = c.valore(.type, "Corsa")
        minutes = c.valore(.minutes, 0)
        km = c.valore(.km, 0.0)
    }
}

enum TipoGiorno: String, CaseIterable, Identifiable {
    case riposo, pesi, cardio
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .riposo: "Riposo"
        case .pesi: "Pesi"
        case .cardio: "Cardio"
        }
    }
    var simbolo: String {
        switch self {
        case .riposo: "moon.zzz"
        case .pesi: "dumbbell"
        case .cardio: "figure.run"
        }
    }
}

// Cosa è stato fatto in un giorno (calendario)
enum Esito: String, CaseIterable, Identifiable {
    case pesi, cardio, saltato
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .pesi: "Pesi fatto"
        case .cardio: "Cardio fatto"
        case .saltato: "Non andato"
        }
    }
}

struct Stato: Codable, Hashable {
    // Settimana A: 2 cardio + 1 pesi. Settimana B: 2 pesi + 1 cardio. Lunedì = 0
    var plans: [String: [String]] = [
        "A": ["cardio", "riposo", "pesi", "riposo", "cardio", "riposo", "riposo"],
        "B": ["pesi", "riposo", "cardio", "riposo", "pesi", "riposo", "riposo"],
    ]
    var swap = false                    // inverte A e B
    var cardioMode = "intervalli"       // "intervalli" oppure "continuo"
    var exercises = Routine.esercizi.map(\.nome)
    var sets: [Serie] = []
    var cardio: [Sessione] = []
    var log: [String: String] = [:]             // data → pesi | cardio | saltato
    var checks: [String: [String: Bool]] = [:]  // data → riscaldamento e defaticamento spuntati
    var payments: [String: String] = [:]        // yyyy-MM → data del pagamento

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = Stato()
        guard let piani = try c.decodeIfPresent([String: [String]].self, forKey: .plans),
              piani["A"]?.count == 7, piani["B"]?.count == 7 else {
            throw DecodingError.dataCorruptedError(forKey: .plans, in: c, debugDescription: "Piano non valido")
        }
        plans = piani
        swap = c.valore(.swap, base.swap)
        cardioMode = c.valore(.cardioMode, base.cardioMode)
        exercises = c.valore(.exercises, base.exercises)
        sets = c.valore(.sets, [])
        cardio = c.valore(.cardio, [])
        log = c.valore(.log, [:])
        checks = c.valore(.checks, [:])
        payments = c.valore(.payments, [:])
    }
}

extension KeyedDecodingContainer {
    // Legge un campo se c'è ed è valido, altrimenti usa il valore predefinito
    func valore<T: Decodable>(_ chiave: Key, _ predefinito: T) -> T {
        ((try? decodeIfPresent(T.self, forKey: chiave)) ?? nil) ?? predefinito
    }
}

// Scheda, riscaldamento e defaticamento (come nella web app)
enum Routine {
    struct Esercizio {
        let nome: String
        let obiettivo: String
    }

    static let esercizi = [
        Esercizio(nome: "Leg press", obiettivo: "3 × 10–12"),
        Esercizio(nome: "Chest press", obiettivo: "3 × 10–12"),
        Esercizio(nome: "Lat machine", obiettivo: "3 × 10–12"),
        Esercizio(nome: "Leg curl", obiettivo: "3 × 10–12"),
        Esercizio(nome: "Shoulder press", obiettivo: "3 × 10–12"),
        Esercizio(nome: "Seated row", obiettivo: "3 × 10–12"),
        Esercizio(nome: "Addominali", obiettivo: "3 × 15"),
    ]

    static func obiettivo(_ nome: String) -> String? { esercizi.first { $0.nome == nome }?.obiettivo }

    // Numero di serie previste (il primo numero dell'obiettivo)
    static func serie(_ nome: String) -> Int? {
        obiettivo(nome).flatMap { Int($0.prefix { $0.isNumber }) }
    }

    static let tipiCardio = ["Corsa", "Bici", "Ellittica", "Nuoto", "Camminata"]

    static let riscaldamento: [TipoGiorno: [String]] = [
        .pesi: ["Cardio leggero (5 min)", "Mobilità dinamica (3–5 min): spalle, anche, schiena"],
        .cardio: ["Cardio leggero 8 min", "Allunghi dinamici (2 min)"],
    ]

    static let defaticamento: [TipoGiorno: String] = [
        .pesi: "5–7 min di stretching leggero",
        .cardio: "5–7 min a ritmo lento",
    ]

    // Spiegazione di ogni esercizio di riscaldamento (10–15 ripetizioni per movimento, senza affaticarsi)
    static let comeSiFa: [TipoGiorno: [(String, String)]] = [
        .pesi: [
            ("Cardio leggero (5 min)", "Tapis roulant a passo veloce o cyclette a ritmo facile: devi riuscire a parlare senza fatica."),
            ("Cerchi con le braccia (10 avanti, 10 indietro)", "Braccia tese ai lati, fai cerchi piccoli che diventano più ampi. Scalda spalle e scapole."),
            ("Oscillazioni delle gambe (10 per lato)", "In piedi, con una mano di appoggio, oscilla la gamba avanti e indietro, poi di lato. Scalda anche e femorali."),
            ("Squat a corpo libero (10 lenti)", "Piedi alla larghezza delle spalle, scendi lentamente e risali. Scalda ginocchia e caviglie."),
            ("Gatto-cammello (8 lenti)", "A quattro zampe: inarca la schiena verso il basso e poi verso l'alto, lentamente. Scalda la colonna."),
            ("Rotazione del busto (6 per lato)", "In piedi, braccia aperte, ruota il busto da una parte e dall'altra tenendo il bacino fermo."),
        ],
        .cardio: [
            ("Cardio leggero (8 min)", "Stesso ritmo facile del cardio: all'inizio cammina, poi aumenta gradualmente."),
            ("Oscillazioni delle gambe (10 per lato)", "Come sopra: scalda anche e femorali prima degli intervalli."),
            ("Allunghi dinamici (2 min): affondi", "In piedi, fai un passo avanti con una gamba e piega entrambe le ginocchia, finché il ginocchio dietro si avvicina a terra senza toccarla. Spingi con il piede davanti per tornare su. Busto dritto. Fai 5 affondi per gamba, poi cambia gamba. Scalda quadricipiti e anche."),
        ],
    ]
}
