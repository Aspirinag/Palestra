# Palestra come app per iPhone

L'app è la stessa pagina `index.html` (che continua a funzionare anche come web app su GitHub Pages),
impacchettata in un'app iOS vera con [Capacitor](https://capacitorjs.com).
Nell'app i dati sono salvati anche nelle preferenze di iOS, quindi il sistema non li cancella.

## Prima volta (sul Mac)

1. Installa **Xcode** dall'App Store (aprilo una volta e accetta la licenza).
2. Installa **Node.js** da <https://nodejs.org> (versione LTS).
3. In Xcode: *Settings → Accounts → +* e accedi con il tuo Apple ID (gratis, non serve l'account sviluppatore).
4. Sull'iPhone: *Impostazioni → Privacy e sicurezza → Modalità sviluppatore* → attiva (compare dopo aver collegato l'iPhone al Mac la prima volta).
5. Nel Terminale:

   ```sh
   git clone https://github.com/aspirinag/Palestra.git
   cd Palestra
   npm install
   npm run ios
   ```

   Si apre Xcode con il progetto.
6. In Xcode seleziona il progetto **App → Signing & Capabilities → Team** → il tuo nome (*Personal Team*).
   Se dice che il Bundle Identifier è già usato, cambialo (es. aggiungi il tuo nome in fondo).
7. Collega l'iPhone con il cavo, sceglilo in alto come destinazione e premi **▶︎**.
8. La prima volta sull'iPhone: *Impostazioni → Generali → VPN e gestione dispositivi* → autorizza il tuo Apple ID.

## Ogni 7 giorni

Con l'Apple ID gratuito l'app scade dopo 7 giorni (i dati restano). Per rinnovarla basta collegare l'iPhone e premere di nuovo **▶︎** in Xcode.
Con l'Apple Developer Program (99 €/anno) dura un anno e si può installare con TestFlight.

## Dopo una modifica a index.html

```sh
git pull
npm run ios
```

e premi **▶︎** in Xcode.

## Passare i dati dalla web app all'app

1. Nella web app: **Esporta backup** e salva il file (es. in *File*).
2. Nell'app: **Importa backup** e scegli quel file.

## Notifiche

Al primo avvio l'app chiede il permesso per le notifiche:
- il giorno 1 di ogni mese alle 9:00 ricorda il pagamento della palestra;
- il timer di recupero avvisa (con suono) quando finisce, anche a telefono bloccato.
