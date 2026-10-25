import SwiftUI
import UniformTypeIdentifiers

// Piano settimanale A/B e backup
struct PianoView: View {
    @Environment(Archivio.self) private var archivio
    @State private var importa = false
    @State private var backupLetto: Data?
    @State private var errore: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Questa settimana", value: archivio.settimana(Giorni.oggi()))
                    Toggle("Scambia A e B", isOn: Binding(
                        get: { archivio.stato.swap },
                        set: { archivio.stato.swap = $0 }
                    ))
                } footer: {
                    Text("Settimana A: 2 giorni di cardio e 1 di pesi. Settimana B: 2 giorni di pesi e 1 di cardio. Le settimane si alternano da sole.")
                }
                settimana("A")
                settimana("B")
                backup
            }
            .navigationTitle("Piano")
            .fileImporter(isPresented: $importa, allowedContentTypes: [.json]) { risultato in
                guard case .success(let url) = risultato else { return }
                let accesso = url.startAccessingSecurityScopedResource()
                defer { if accesso { url.stopAccessingSecurityScopedResource() } }
                backupLetto = try? Data(contentsOf: url)
            }
            .alert("Importare il backup?", isPresented: Binding(
                get: { backupLetto != nil }, set: { if !$0 { backupLetto = nil } }
            ), presenting: backupLetto) { dati in
                Button("Importa", role: .destructive) {
                    do { try archivio.importa(dati) } catch { errore = "File non valido: scegli un backup esportato dall'app Palestra." }
                }
                Button("Annulla", role: .cancel) {}
            } message: { _ in
                Text("Il backup sostituisce tutti i dati attuali.")
            }
            .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK") {}
            } message: {
                Text(errore ?? "")
            }
        }
    }

    private func settimana(_ w: String) -> some View {
        Section("Settimana \(w)") {
            ForEach(0..<7, id: \.self) { i in
                Picker(Giorni.nomi[i], selection: Binding(
                    get: { TipoGiorno(rawValue: archivio.stato.plans[w]?[i] ?? "") ?? .riposo },
                    set: { archivio.stato.plans[w]?[i] = $0.rawValue }
                )) {
                    ForEach(TipoGiorno.allCases) { t in
                        Label(t.nome, systemImage: t.simbolo).tag(t)
                    }
                }
            }
        }
    }

    private var backup: some View {
        Section {
            ShareLink(
                item: FileBackup(dati: archivio.backup(), nome: "palestra-backup-\(Giorni.oggi()).json"),
                preview: SharePreview("Backup Palestra")
            ) {
                Label("Esporta backup", systemImage: "square.and.arrow.up")
            }
            Button("Importa backup", systemImage: "square.and.arrow.down") { importa = true }
        } header: {
            Text("Backup")
        } footer: {
            Text("Il backup è lo stesso della web app: esportalo dalla web app e importalo qui per portare i dati nell'app.")
        }
    }
}
