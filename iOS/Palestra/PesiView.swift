import SwiftUI
import Charts

// Scheda pesi: serie di oggi, nuove serie, progressi e storico per giorno
struct PesiView: View {
    @Environment(Archivio.self) private var archivio
    @State private var nuovoEsercizio = ""
    @State private var daModificare: Int?
    @FocusState private var campo: String?

    var body: some View {
        NavigationStack {
            List {
                SezioneTimer()
                ForEach(archivio.stato.exercises, id: \.self) { nome in
                    SchedaEsercizio(nome: nome, campo: $campo)
                }
                Section {
                    HStack {
                        TextField("Nuovo esercizio", text: $nuovoEsercizio)
                            .focused($campo, equals: "nuovo")
                            .submitLabel(.done)
                            .onSubmit(aggiungi)
                        Button("Aggiungi", action: aggiungi)
                            .pulsanteVetro()
                            .disabled(nuovoEsercizio.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                StoricoSerie(daModificare: $daModificare)
            }
            .navigationTitle("Scheda pesi")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fine") { campo = nil }
                }
            }
            .sheet(item: Binding(
                get: { daModificare.map { IndiceSerie(id: $0) } },
                set: { daModificare = $0?.id }
            )) { i in
                EditorSerie(indice: i.id)
            }
        }
    }

    private func aggiungi() {
        let n = nuovoEsercizio.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, !archivio.stato.exercises.contains(n) else { return }
        archivio.stato.exercises.append(n)
        nuovoEsercizio = ""
    }
}

struct IndiceSerie: Identifiable {
    let id: Int
}

struct SchedaEsercizio: View {
    @Environment(Archivio.self) private var archivio
    let nome: String
    var campo: FocusState<String?>.Binding
    @State private var kg = ""
    @State private var rip = ""
    @State private var chiediRimozione = false

    var body: some View {
        let ultima = archivio.ultimaSerie(nome, esclusoOggi: true) ?? archivio.ultimaSerie(nome)
        let oggi = archivio.serieDiOggi(nome)
        let suggerita = oggi.last ?? ultima
        Section {
            intestazione
            if let ultima {
                LabeledContent("Ultima volta", value: "\(num(ultima.kg)) kg × \(ultima.reps) · \(Giorni.breve(ultima.date))")
                    .font(.subheadline)
            }
            if !oggi.isEmpty { serieDiOggi(oggi) }
            HStack(spacing: 8) {
                TextField(suggerita.map { "kg (\(num($0.kg)))" } ?? "kg", text: $kg)
                    .keyboardType(.decimalPad)
                    .focused(campo, equals: nome + "-kg")
                    .textFieldStyle(.roundedBorder)
                TextField(suggerita.map { "rip. (\($0.reps))" } ?? "rip.", text: $rip)
                    .keyboardType(.numberPad)
                    .focused(campo, equals: nome + "-rip")
                    .textFieldStyle(.roundedBorder)
                Button("Salva") { salva(suggerita) }
                    .pulsanteVetro(evidente: true)
            }
            grafico
        }
        .confirmationDialog("Rimuovere \(nome) dalla scheda?", isPresented: $chiediRimozione, titleVisibility: .visible) {
            Button("Rimuovi", role: .destructive) { archivio.stato.exercises.removeAll { $0 == nome } }
        } message: {
            Text("Lo storico delle serie resta.")
        }
    }

    private var intestazione: some View {
        HStack(spacing: 14) {
            Pittogramma(figura: .per(nome))
            VStack(alignment: .leading, spacing: 2) {
                Text(nome).font(.headline)
                if let o = Routine.obiettivo(nome) {
                    Text("Obiettivo: \(o)").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Menu {
                Button("Rimuovi dalla scheda", systemImage: "trash", role: .destructive) { chiediRimozione = true }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title3)
            }
        }
    }

    private func serieDiOggi(_ oggi: [Serie]) -> some View {
        let previste = Routine.serie(nome)
        let completate = previste.map { oggi.count >= $0 } ?? false
        return HStack {
            Image(systemName: completate ? "checkmark.seal.fill" : "flame.fill")
            Text("Oggi \(previste.map { "\(oggi.count)/\($0)" } ?? "\(oggi.count)") serie")
                .fontWeight(.semibold)
            Text(oggi.map { "\(num($0.kg))×\($0.reps)" }.joined(separator: " · "))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.subheadline)
        .foregroundStyle(.tint)
    }

    @ViewBuilder private var grafico: some View {
        let punti = archivio.progressi(nome)
        if punti.count >= 2 {
            Chart(Array(punti.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("Data", p.data), y: .value("kg", p.kg))
                    .interpolationMethod(.monotone)
                PointMark(x: .value("Data", p.data), y: .value("kg", p.kg))
                    .symbolSize(24)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine()
                    AxisValueLabel { if let kg = v.as(Double.self) { Text("\(num(kg)) kg") } }
                }
            }
            .frame(height: 80)
            .accessibilityLabel("Carico massimo per giornata")
        }
    }

    // Campi vuoti: vale il valore suggerito tra parentesi (ultima serie)
    private func salva(_ suggerita: Serie?) {
        let k = leggiNumero(kg) ?? (kg.isEmpty ? suggerita?.kg : nil)
        let r = Int(rip) ?? (rip.isEmpty ? suggerita?.reps : nil)
        guard let k, let r, r > 0 else { return }
        archivio.salvaSerie(nome, kg: k, reps: r)
        kg = ""
        rip = ""
        campo.wrappedValue = nil
    }
}

struct StoricoSerie: View {
    @Environment(Archivio.self) private var archivio
    @Binding var daModificare: Int?

    var body: some View {
        let perData = Dictionary(grouping: archivio.stato.sets.indices, by: { archivio.stato.sets[$0].date })
        let date = perData.keys.sorted(by: >).prefix(15)
        if date.isEmpty {
            Section("Storico") { Text("Nessuna serie registrata.").foregroundStyle(.secondary) }
        }
        ForEach(Array(date), id: \.self) { d in
            Section(d == date.first ? "Storico · \(Giorni.breve(d))" : Giorni.breve(d)) {
                ForEach(perData[d] ?? [], id: \.self) { i in
                    let s = archivio.stato.sets[i]
                    Button { daModificare = i } label: {
                        LabeledContent(s.exercise, value: "\(num(s.kg)) kg × \(s.reps)")
                            .foregroundStyle(.primary)
                    }
                    .tint(.primary)
                    .swipeActions {
                        Button("Elimina", systemImage: "trash", role: .destructive) {
                            archivio.stato.sets.remove(at: i)
                        }
                    }
                }
            }
        }
    }
}

struct EditorSerie: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    let indice: Int
    @State private var kg = ""
    @State private var rip = ""

    var body: some View {
        NavigationStack {
            Form {
                if archivio.stato.sets.indices.contains(indice) {
                    let s = archivio.stato.sets[indice]
                    Section("\(s.exercise) · \(Giorni.breve(s.date))") {
                        LabeledContent("Carico (kg)") {
                            TextField("kg", text: $kg).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                        LabeledContent("Ripetizioni") {
                            TextField("rip.", text: $rip).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        }
                    }
                    Section {
                        Button("Elimina serie", role: .destructive) {
                            archivio.stato.sets.remove(at: indice)
                            chiudi()
                        }
                    }
                }
            }
            .navigationTitle("Modifica serie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla", role: .cancel) { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        if let k = leggiNumero(kg), let r = Int(rip), archivio.stato.sets.indices.contains(indice) {
                            archivio.stato.sets[indice].kg = k
                            archivio.stato.sets[indice].reps = r
                        }
                        chiudi()
                    }
                }
            }
            .onAppear {
                guard archivio.stato.sets.indices.contains(indice) else { return }
                kg = num(archivio.stato.sets[indice].kg)
                rip = String(archivio.stato.sets[indice].reps)
            }
        }
        .presentationDetents([.medium])
    }
}
