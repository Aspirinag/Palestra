import SwiftUI

// Allenamento di oggi (o il prossimo): riscaldamento, parte centrale, defaticamento
struct OggiView: View {
    @Environment(Archivio.self) private var archivio
    @State private var scelta: TipoGiorno?

    var body: some View {
        let oggi = Giorni.oggi()
        let programmato = archivio.programmato(oggi)
        let attivo = scelta ?? archivio.prossimoAllenamento()
        NavigationStack {
            List {
                SezionePagamento()
                Section {
                    LabeledContent("Settimana", value: archivio.settimana(oggi))
                    LabeledContent("Programmato") {
                        HStack(spacing: 6) {
                            Image(systemName: programmato.simbolo).foregroundStyle(.tint)
                            Text(programmato.nome)
                        }
                    }
                } footer: {
                    if programmato == .riposo { Text("Oggi è riposo: ti mostro il prossimo allenamento.") }
                }
                Section {
                    Picker("Allenamento", selection: Binding(get: { attivo }, set: { scelta = $0 })) {
                        Text("Cardio").tag(TipoGiorno.cardio)
                        Text("Pesi").tag(TipoGiorno.pesi)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                if attivo == .cardio { OggiCardio() } else { OggiPesi() }
                if programmato != .riposo { SezioneSaltato() }
                SezioneTimer()
            }
            .navigationTitle("Oggi, \(Giorni.nomi[Giorni.indice(oggi)].lowercased())")
        }
    }
}

// Riga della checklist di oggi (riscaldamento, defaticamento)
struct RigaChecklist: View {
    @Environment(Archivio.self) private var archivio
    let chiave: String
    let testo: String

    var body: some View {
        RigaSpunta(fatto: archivio.spuntato(chiave), azione: { archivio.spunta(chiave) }) {
            Text(testo)
        }
    }
}

struct ComeSiFa: View {
    let tipo: TipoGiorno
    @State private var aperto = false

    var body: some View {
        DisclosureGroup("Come si fa", isExpanded: $aperto) {
            ForEach(Array((Routine.comeSiFa[tipo] ?? []).enumerated()), id: \.offset) { i, voce in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(i + 1). \(voce.0)").font(.subheadline.weight(.semibold))
                    Text(voce.1).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct OggiCardio: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Navigazione.self) private var navigazione

    var body: some View {
        Section("Riscaldamento") {
            ForEach(Array((Routine.riscaldamento[.cardio] ?? []).enumerated()), id: \.offset) { i, t in
                RigaChecklist(chiave: "cardio-w\(i)", testo: t)
            }
            ComeSiFa(tipo: .cardio)
        }
        Section("Parte centrale") {
            HStack(spacing: 14) {
                Pittogramma(figura: .corsa)
                Text(archivio.stato.cardioMode == "intervalli" ? "3 × (3 min sostenuti + 2 min lenti)" : "30 min sostenuti")
                    .font(.headline)
            }
            Picker("Tipo", selection: Binding(
                get: { archivio.stato.cardioMode },
                set: { archivio.stato.cardioMode = $0 }
            )) {
                Text("3 × intervalli").tag("intervalli")
                Text("30 min continui").tag("continuo")
            }
            .pickerStyle(.segmented)
        }
        Section("Defaticamento") {
            RigaChecklist(chiave: "cardio-d0", testo: Routine.defaticamento[.cardio] ?? "")
        }
        Section {
            Button {
                navigazione.scheda = .cardio
            } label: {
                Label("Registra sessione cardio", systemImage: "square.and.pencil").frame(maxWidth: .infinity)
            }
            .pulsanteVetro(evidente: true)
            .controlSize(.large)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
}

struct OggiPesi: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Navigazione.self) private var navigazione

    private let rampa: [(Double, String)] = [(0.5, "8–10"), (0.7, "4–6"), (0.85, "2–3")]

    var body: some View {
        let primo = archivio.stato.exercises.first
        Section {
            ForEach(Array((Routine.riscaldamento[.pesi] ?? []).enumerated()), id: \.offset) { i, t in
                RigaChecklist(chiave: "pesi-w\(i)", testo: t)
            }
            ComeSiFa(tipo: .pesi)
            if let primo {
                ForEach(Array(rampa.enumerated()), id: \.offset) { i, r in
                    RigaChecklist(chiave: "pesi-r\(i)", testo: "\(primo): \(archivio.avvicinamento(primo, r.0)) × \(r.1) rip.")
                }
            }
        } header: {
            Text("Riscaldamento")
        } footer: {
            Text("Serie di avvicinamento con peso crescente. Riposa 30–60 secondi tra una serie e l'altra.")
        }
        Section("Esercizi") {
            ForEach(archivio.stato.exercises, id: \.self) { nome in
                HStack(spacing: 14) {
                    Pittogramma(figura: .per(nome))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nome).font(.headline)
                        if let o = Routine.obiettivo(nome) {
                            Text("Obiettivo: \(o)").font(.subheadline).foregroundStyle(.secondary)
                        }
                        if nome != primo {
                            Text("Avvicinamento: \(archivio.avvicinamento(nome, 0.5)) × 8–10 rip.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        Section("Defaticamento") {
            RigaChecklist(chiave: "pesi-d0", testo: Routine.defaticamento[.pesi] ?? "")
        }
        Section {
            Button {
                navigazione.scheda = .pesi
            } label: {
                Label("Apri scheda pesi", systemImage: "dumbbell").frame(maxWidth: .infinity)
            }
            .pulsanteVetro(evidente: true)
            .controlSize(.large)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
}

struct SezioneSaltato: View {
    @Environment(Archivio.self) private var archivio

    var body: some View {
        let oggi = Giorni.oggi()
        let saltato = archivio.stato.log[oggi] == Esito.saltato.rawValue
        Section {
            Button(saltato ? "Annulla “non sono andato”" : "Non sono andato oggi",
                   systemImage: saltato ? "arrow.uturn.backward" : "xmark.circle") {
                archivio.stato.log[oggi] = saltato ? nil : Esito.saltato.rawValue
            }
            .foregroundStyle(saltato ? AnyShapeStyle(.tint) : AnyShapeStyle(.red))
        }
    }
}
