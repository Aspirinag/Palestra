# Palestra per iPhone

Ci sono due versioni:

- **App per iPhone** (cartella `iOS/`): app nativa in SwiftUI, con l'interfaccia di iOS (Liquid Glass su iOS 26). Serve iOS 18 o successivo.
- **Web app** (`index.html`), pubblicata su GitHub Pages: funziona in qualunque browser.

I dati non si sincronizzano tra le due: per passare da una all'altra usa **Esporta backup** e **Importa backup**. Il file è lo stesso in entrambe.

## Installazione con SideStore (gratis)

A ogni modifica su `main`, GitHub compila l'app e la pubblica nelle *Releases* del repository.
SideStore la installa firmandola con il tuo Apple ID gratuito e la rinnova da solo ogni 7 giorni via Wi‑Fi.

1. Installa SideStore sull'iPhone seguendo la guida ufficiale: <https://docs.sidestore.io> (serve il Mac solo questa volta).
2. In SideStore: *Sources → +* e incolla questo indirizzo:

   ```
   https://github.com/aspirinag/Palestra/releases/latest/download/sidestore.json
   ```

3. Apri la sorgente **Palestra** e tocca **Installa**.
4. Gli aggiornamenti compaiono in SideStore (*My Apps → Update*). Apri SideStore ogni tanto per rinnovare le app.

Con l'Apple ID gratuito si possono avere al massimo 3 app installate così (SideStore compreso).

## Portare i dati dalla web app

1. Nella web app: **Esporta backup** e salva il file (es. in *File*).
2. Nell'app: **Importa backup** e scegli quel file.

## Compilare dal Mac con Xcode

1. Installa **Xcode 26** dall'App Store.
2. Apri `iOS/Palestra.xcodeproj`.
3. *Signing & Capabilities → Team* → il tuo Apple ID (*Personal Team*). Se il Bundle Identifier è già usato, cambialo.
4. Collega l'iPhone, sceglilo in alto come destinazione e premi **▶︎**.

## Schermate di prova

Sugli altri branch GitHub Actions compila l'app per il simulatore e salva le schermate (chiaro e scuro, con dati di prova)
nel branch `schermate`. Per vedere l'app con i dati di prova dal Mac: in Xcode, *Product → Scheme → Edit Scheme → Run → Arguments*, aggiungi `-demo`.
