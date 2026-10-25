import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

@main
struct PalestraApp: App {
    @State private var archivio = Archivio()
    @State private var timer = TimerRecupero()
    @State private var navigazione = Navigazione()
    private let delegato = DelegatoNotifiche()

    init() {
        UNUserNotificationCenter.current().delegate = delegato
    }

    var body: some Scene {
        WindowGroup {
            Radice()
                .environment(archivio)
                .environment(timer)
                .environment(navigazione)
        }
    }
}

enum Scheda: String {
    case oggi, pesi, cardio, calendario, piano
}

// Scheda selezionata: anche i pulsanti dentro le schermate possono cambiarla
@Observable
final class Navigazione {
    var scheda = Scheda(rawValue: Avvio.valore("-tab") ?? "") ?? .oggi
}

struct Radice: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Navigazione.self) private var navigazione

    var body: some View {
        @Bindable var navigazione = navigazione
        TabView(selection: $navigazione.scheda) {
            Tab("Oggi", systemImage: "house", value: .oggi) { OggiView() }
            Tab("Pesi", systemImage: "dumbbell", value: .pesi) { PesiView() }
            Tab("Cardio", systemImage: "figure.run", value: .cardio) { CardioView() }
            Tab("Calendario", systemImage: "calendar", value: .calendario) { CalendarioView() }
            Tab("Piano", systemImage: "list.bullet.rectangle", value: .piano) { PianoView() }
        }
        .accessorioTimer()
        .task {
            guard !archivio.demo else { return }
            if await Notifiche.permesso() { await archivio.programmaPagamento() }
        }
    }
}

extension View {
    // Su iOS 26 il timer di recupero sta sopra la tab bar, in vetro; prima di iOS 26 è dentro Oggi e Pesi
    @ViewBuilder
    func accessorioTimer() -> some View {
        if #available(iOS 26.0, *) {
            tabViewBottomAccessory { BarraTimer() }
        } else {
            self
        }
    }
}

// Timer dentro la lista, solo prima di iOS 26
struct SezioneTimer: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            EmptyView()
        } else {
            Section("Timer di recupero") {
                BarraTimer().listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            }
        }
    }
}

// Avviso di pagamento dal 25 al 2 del mese, finché non è segnato pagato
struct SezionePagamento: View {
    @Environment(Archivio.self) private var archivio

    var body: some View {
        if let p = archivio.promemoriaPagamento() {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pagamento palestra").font(.headline)
                        Text(p.testo).font(.subheadline).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "creditcard.fill").foregroundStyle(.tint)
                }
                Button("Segna pagato", systemImage: "checkmark.circle") { archivio.segnaPagato(p.mese) }
            }
        }
    }
}

// Backup condivisibile come file .json
struct FileBackup: Transferable {
    let dati: Data
    let nome: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.dati }
            .suggestedFileName { $0.nome }
    }
}
