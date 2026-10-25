import SwiftUI

// Calendario del mese: allenamenti fatti, programmati e saltati; pagamento della palestra
struct CalendarioView: View {
    @Environment(Archivio.self) private var archivio
    @State private var mese = Giorni.data(String(Giorni.oggi().prefix(8)) + "01")
    @State private var scelto = Giorni.oggi()

    private var titoloMese: String {
        mese.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "it_IT"))).capitalized
    }

    var body: some View {
        NavigationStack {
            List {
                SezionePagamento()
                Section {
                    GrigliaMese(mese: mese, scelto: $scelto)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                } footer: {
                    Text("Pallino pieno: allenamento fatto. Pallino chiaro: programmato. ✕: non andato.")
                }
                giornoScelto
                pagamento
            }
            .navigationTitle(titoloMese)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Mese precedente", systemImage: "chevron.left") { cambiaMese(-1) }
                    Button("Mese successivo", systemImage: "chevron.right") { cambiaMese(1) }
                }
            }
        }
    }

    private func cambiaMese(_ n: Int) {
        mese = Giorni.calendario.date(byAdding: .month, value: n, to: mese) ?? mese
    }

    private var giornoScelto: some View {
        let esito = archivio.stato.log[scelto].flatMap(Esito.init(rawValue:))
        let programmato = archivio.programmato(scelto)
        return Section {
            LabeledContent("Programmato") {
                HStack(spacing: 6) {
                    Image(systemName: programmato.simbolo).foregroundStyle(.tint)
                    Text(programmato.nome)
                }
            }
            HStack(spacing: 8) {
                ForEach(Esito.allCases) { e in
                    Button(e.nome) {
                        archivio.stato.log[scelto] = esito == e ? nil : e.rawValue
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .pulsanteVetro(evidente: esito == e)
                    .tint(e == .saltato ? .red : e == .cardio ? .blue : .accentColor)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        } header: {
            Text(Giorni.nomi[Giorni.indice(scelto)] + " " + Giorni.breve(scelto))
        }
    }

    private var pagamento: some View {
        let m = Archivio.mese(Giorni.iso(mese))
        let pagato = archivio.stato.payments[m]
        return Section("Pagamento di \(titoloMese.lowercased())") {
            if let pagato {
                LabeledContent("Pagato il", value: Giorni.breve(pagato))
                Button("Annulla pagamento", systemImage: "arrow.uturn.backward", role: .destructive) {
                    archivio.annullaPagamento(m)
                }
            } else {
                LabeledContent("Stato", value: "Non ancora pagato")
                Button("Segna pagato", systemImage: "checkmark.circle") { archivio.segnaPagato(m) }
            }
        }
    }
}

struct GrigliaMese: View {
    @Environment(Archivio.self) private var archivio
    let mese: Date
    @Binding var scelto: String

    var body: some View {
        let cal = Giorni.calendario
        let primo = Giorni.iso(mese)
        let vuoti = Giorni.indice(primo)
        let giorni = cal.range(of: .day, in: .month, for: mese)?.count ?? 30
        let oggi = Giorni.oggi()
        // Griglia non lazy: dentro una lista la griglia lazy viene misurata male e si taglia
        let celle: [Int?] = Array(repeating: nil, count: vuoti) + (0..<giorni).map { Optional($0) }
        let settimane = stride(from: 0, to: celle.count, by: 7).map { Array(celle[$0..<min($0 + 7, celle.count)]) }
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                ForEach(["L", "M", "M", "G", "V", "S", "D"].indices, id: \.self) { i in
                    Text(["L", "M", "M", "G", "V", "S", "D"][i])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(settimane.indices, id: \.self) { w in
                GridRow {
                    ForEach(0..<7, id: \.self) { i in
                        if i < settimane[w].count, let d = settimane[w][i] {
                            cella(primo: primo, giorno: d, oggi: oggi)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                }
            }
        }
    }

    private func cella(primo: String, giorno d: Int, oggi: String) -> some View {
        let iso = Giorni.aggiungi(primo, d)
        return Button { scelto = iso } label: {
            VStack(spacing: 3) {
                Text("\(d + 1)")
                    .font(.callout.weight(iso == oggi ? .bold : .regular))
                    .foregroundStyle(iso == oggi ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                segno(iso)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if iso == scelto {
                    RoundedRectangle(cornerRadius: 12).fill(.tint.opacity(0.18))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func segno(_ iso: String) -> some View {
        switch archivio.stato.log[iso].flatMap(Esito.init(rawValue:)) {
        case .saltato:
            Image(systemName: "xmark").font(.system(size: 9, weight: .heavy)).foregroundStyle(.red).frame(height: 7)
        case .pesi:
            Circle().fill(.tint).frame(width: 7, height: 7)
        case .cardio:
            Circle().fill(.blue).frame(width: 7, height: 7)
        case nil:
            Circle().fill(archivio.programmato(iso) != .riposo ? AnyShapeStyle(.secondary.opacity(0.5)) : AnyShapeStyle(.clear))
                .frame(width: 7, height: 7)
        }
    }
}
