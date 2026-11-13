# Tiro alla fune

Un gioco a due per la **Touch Bar** del MacBook Pro: ogni giocatore martella la propria metà della barra e la corda si sposta verso chi tira più veloce. La grafica è disegnata interamente dal codice: nessun file di immagine.

![La partita sulla Touch Bar](docs/partenza.png)

**[⬇️ Scarica l'ultima versione](https://github.com/AlbyToniolo-byte/tiro-alla-fune/releases/latest)**

## Come si gioca

- Dopo il conto alla rovescia **3, 2, 1**, il **blu** tocca la metà sinistra della barra e il **rosso** la destra. Conta ogni dito che appoggia: si può martellare anche con più dita.
- Ogni tocco tira la corda di un passo. Vince chi porta il fiocco giallo oltre la propria linea, con **12 tiri di vantaggio**.
- Dopo la vittoria, un tocco fa partire la rivincita. Il punteggio resta nella finestra.

![Vittoria del blu](docs/vittoria.png)

| Azione | Touch Bar | Tastiera |
|---|---|---|
| Tira per il blu | metà sinistra | A |
| Tira per il rosso | metà destra | L |
| Rivincita | tocca la barra | Spazio |

Tieni la finestra del gioco in primo piano: macOS mostra la Touch Bar solo dell'app attiva.

## Installazione

Serve un **MacBook Pro con Touch Bar** e **macOS 13** o successivo (Apple Silicon o Intel).

1. Scarica `TiroAllaFune.zip` dall'[ultima release](https://github.com/AlbyToniolo-byte/tiro-alla-fune/releases/latest), estrai e sposta **Tiro alla fune** in Applicazioni.
2. L'app non è firmata con un certificato Apple, quindi al primo avvio macOS la blocca: apri **Impostazioni di Sistema → Privacy e sicurezza** e premi **Apri comunque**. In alternativa, dal Terminale:
   ```bash
   xattr -dr com.apple.quarantine "/Applications/Tiro alla fune.app"
   ```

## Compilare dal codice

Bastano gli strumenti da riga di comando di Xcode (`xcode-select --install`).

```bash
./build.sh   # esegue i test e crea "Tiro alla fune.app" (universale)
```

Tutto il gioco è in [`main.swift`](main.swift): AppKit per finestra e Touch Bar (`NSCustomTouchBarItem` con tocchi diretti, così ogni dito arriva con la sua posizione), disegno con `NSBezierPath` a 60 fotogrammi al secondo. `./build.sh` lancia prima un self-test della partita (conto alla rovescia, tiri, vittoria, rivincita).
