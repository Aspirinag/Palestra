import SwiftUI

// Nuova sessione cardio e storico
struct CardioView: View {
    @Environment(Archivio.self) private var archivio
    @State private var tipo = Routine.tipiCardio[0]
    @State private var minuti = ""
    @State private var km = ""
    @State private var daModificare: Int?
    @FocusState private var campo: Bool

    var body: some View {
        NavigationStack {
            List {
                nuova
                storico
            }
            .navigationTitle("Cardio")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fine") { campo = false }
                }
            }
            .sheet(item: Binding(
                get: { daModificare.map { IndiceSerie(id: $0) } },
                set: { daModificare = $0?.id }
            )) { i in
                EditorSessione(indice: i.id)
            }
        }
    }

    private var nuova: some View {
        Section("Nuova sessione") {
            Picker("Tipo", selection: $tipo) {
                ForEach(Routine.tipiCardio, id: \.self) { Text($0).tag($0) }
            }
            LabeledContent("Minuti") {
                TextField("30", text: $minuti)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($campo)
            }
            LabeledContent("Km (facoltativi)") {
                TextField("0", text: $km)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($campo)
            }
            Button {
                guard let m = Int(minuti), m > 0 else { return }
                archivio.salvaCardio(tipo: tipo, minuti: m, km: leggiNumero(km) ?? 0)
                minuti = ""
                km = ""
                campo = false
            } label: {
                Label("Salva sessione", systemImage: "checkmark").frame(maxWidth: .infinity)
            }
            .pulsanteVetro(evidente: true)
            .controlSize(.large)
            .disabled((Int(minuti) ?? 0) <= 0)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    @ViewBuilder private var storico: some View {
        Section("Storico") {
            if archivio.stato.cardio.isEmpty {
                Text("Nessuna sessione registrata.").foregroundStyle(.secondary)
            }
            ForEach(archivio.stato.cardio.indices, id: \.self) { i in
                let c = archivio.stato.cardio[i]
                Button { daModificare = i } label: {
                    HStack(spacing: 12) {
                        Image(systemName: simbolo(c.type)).foregroundStyle(.tint).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(c.type) · \(c.minutes) min" + (c.km > 0 ? " · \(num(c.km)) km" : ""))
                                .foregroundStyle(.primary)
                            Text(Giorni.breve(c.date)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .swipeActions {
                    Button("Elimina", systemImage: "trash", role: .destructive) { archivio.stato.cardio.remove(at: i) }
                }
            }
        }
    }

    private func simbolo(_ tipo: String) -> String {
        switch tipo {
        case "Bici": "figure.outdoor.cycle"
        case "Ellittica": "figure.elliptical"
        case "Nuoto": "figure.pool.swim"
        case "Camminata": "figure.walk"
        default: "figure.run"
        }
    }
}

struct EditorSessione: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    let indice: Int
    @State private var minuti = ""
    @State private var km = ""

    var body: some View {
        NavigationStack {
            Form {
                if archivio.stato.cardio.indices.contains(indice) {
                    let c = archivio.stato.cardio[indice]
                    Section("\(c.type) · \(Giorni.breve(c.date))") {
                        LabeledContent("Minuti") {
                            TextField("min", text: $minuti).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        }
                        LabeledContent("Km") {
                            TextField("0", text: $km).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    Section {
                        Button("Elimina sessione", role: .destructive) {
                            archivio.stato.cardio.remove(at: indice)
                            chiudi()
                        }
                    }
                }
            }
            .navigationTitle("Modifica sessione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla", role: .cancel) { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        if let m = Int(minuti), m > 0, archivio.stato.cardio.indices.contains(indice) {
                            archivio.stato.cardio[indice].minutes = m
                            archivio.stato.cardio[indice].km = leggiNumero(km) ?? 0
                        }
                        chiudi()
                    }
                }
            }
            .onAppear {
                guard archivio.stato.cardio.indices.contains(indice) else { return }
                minuti = String(archivio.stato.cardio[indice].minutes)
                km = num(archivio.stato.cardio[indice].km)
            }
        }
        .presentationDetents([.medium])
    }
}
