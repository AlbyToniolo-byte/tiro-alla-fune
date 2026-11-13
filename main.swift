import AppKit

let toWin = 12          // tiri di vantaggio per portare il fiocco sulla propria linea
let countdown = 3.0     // secondi di "3, 2, 1" prima di poter tirare
let restartDelay = 1.5  // dopo la vittoria i tocchi frenetici non fanno ripartire subito
let teams = [(name: "BLU", color: NSColor.systemBlue), (name: "ROSSO", color: NSColor.systemRed)]

/// Squadra 0 (blu) tira verso sinistra, squadra 1 (rosso) verso destra.
func dir(_ side: Int) -> CGFloat { side == 0 ? -1 : 1 }

struct Match {
    var rope = 0       // <0 verso il blu, >0 verso il rosso; si vince a ±toWin
    var time = 0.0     // secondi dall'inizio, conto alla rovescia compreso
    var winner: Int?
    var wonAt = 0.0

    var started: Bool { time >= countdown }
    var canRestart: Bool { winner != nil && time - wonAt >= restartDelay }

    mutating func pull(_ side: Int) {
        guard started, winner == nil else { return }
        rope += side == 0 ? -1 : 1
        if abs(rope) >= toWin { winner = side; wonAt = time }
    }
}

/// Scritta bianca su una pillola scura, centrata in `center`.
func label(_ text: String, at center: NSPoint, size: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: size, weight: .heavy), .foregroundColor: NSColor.white]
    let s = (text as NSString).size(withAttributes: attrs)
    let r = NSRect(x: center.x - s.width / 2 - 7, y: center.y - s.height / 2, width: s.width + 14, height: s.height)
    NSColor.black.withAlphaComponent(0.6).setFill()
    NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2).fill()
    (text as NSString).draw(at: NSPoint(x: r.minX + 7, y: r.minY), withAttributes: attrs)
}

/// Omino stilizzato che tiene la corda all'altezza `ropeY` e si piega verso `back` (-1 sinistra, +1 destra).
func person(x: CGFloat, back: CGFloat, lean: CGFloat, color: NSColor, ropeY: CGFloat) {
    let hip = NSPoint(x: x, y: 9), neck = NSPoint(x: x + back * lean, y: 18)
    let p = NSBezierPath()
    p.lineWidth = 1.6
    p.lineCapStyle = .round
    p.move(to: NSPoint(x: x - back * 6, y: 1.5)); p.line(to: hip); p.line(to: NSPoint(x: x + back, y: 1.5)) // gambe puntate
    p.move(to: hip); p.line(to: neck)
    p.move(to: NSPoint(x: x + back * lean * 0.7, y: 15.5)); p.line(to: NSPoint(x: x - back * 5, y: ropeY)) // braccia tese
    color.setStroke()
    p.stroke()
    color.setFill()
    NSBezierPath(ovalIn: NSRect(x: neck.x + back * lean * 0.25 - 3, y: neck.y + 0.5, width: 6, height: 6)).fill()
}

final class RopeView: NSView {
    var match = Match()
    var score = [0, 0]
    var shown: CGFloat = 0          // posizione disegnata: insegue match.rope per un movimento morbido
    var effort: [CGFloat] = [0, 0]  // quanto si piega ogni squadra: sale a ogni tiro e poi cala

    override init(frame: NSRect) {
        super.init(frame: frame)
        allowedTouchTypes = .direct
    }
    required init?(coder: NSCoder) { fatalError() }

    // ogni dito che appoggia conta: i due giocatori toccano insieme, ognuno sulla sua metà
    override func touchesBegan(with event: NSEvent) {
        for t in event.touches(matching: .began, in: self) {
            press(t.location(in: self).x < visibleRect.midX ? 0 : 1)
        }
    }

    func press(_ side: Int) {
        if match.canRestart { match = Match(); return }
        guard match.started, match.winner == nil else { return }
        match.pull(side)
        effort[side] = 1
        if let w = match.winner { score[w] += 1 }
    }

    func tick(_ dt: Double) {
        match.time += dt
        shown += (CGFloat(match.rope) / CGFloat(toWin) - shown) * min(1, CGFloat(dt) * 12)
        effort = effort.map { max(0, $0 - CGFloat(dt) * 4) }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let v = visibleRect, w = v.width, mid = v.midX, h = bounds.height // la vista può essere più larga della parte visibile
        let reach = w * 0.12, ropeY: CGFloat = 12
        let knot = mid + shown * reach

        NSColor.black.setFill(); bounds.fill()
        for side in 0...1 {
            teams[side].color.withAlphaComponent(0.22).setFill()
            NSRect(x: side == 0 ? v.minX : mid, y: 0, width: w / 2, height: h).fill()
            teams[side].color.setFill() // linea della vittoria
            NSRect(x: mid + dir(side) * reach - 1, y: 2, width: 2, height: h - 4).fill()
        }
        NSColor.white.withAlphaComponent(0.3).setFill()
        NSRect(x: mid - 0.5, y: 3, width: 1, height: h - 6).fill()

        for side in 0...1 {
            for off in [0.18, 0.26] {
                person(x: knot + dir(side) * w * off, back: dir(side), lean: 3 + effort[side] * 4, color: teams[side].color, ropeY: ropeY)
            }
        }
        NSColor(srgbRed: 0.8, green: 0.64, blue: 0.4, alpha: 1).setFill()
        NSRect(x: knot - w * 0.3, y: ropeY - 1, width: w * 0.6, height: 2).fill()
        let flag = NSBezierPath()
        flag.move(to: NSPoint(x: knot, y: ropeY))
        flag.line(to: NSPoint(x: knot - 3.5, y: ropeY - 9))
        flag.line(to: NSPoint(x: knot + 3.5, y: ropeY - 9))
        flag.close()
        NSColor.systemYellow.setFill()
        flag.fill()

        let center = NSPoint(x: mid, y: h / 2 + 4)
        if !match.started {
            label(["3", "2", "1"][min(2, Int(match.time))], at: center, size: 15)
        } else if let win = match.winner {
            label("VINCE IL \(teams[win].name)!" + (match.canRestart ? "  ·  tocca per la rivincita" : ""), at: center, size: 13)
        } else if match.time < countdown + 0.7 {
            label("TIRA!", at: center, size: 15)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let ropeView = RopeView(frame: NSRect(x: 0, y: 0, width: 600, height: 30))
    let scoreLabel = NSTextField(labelWithString: "")
    var window: NSWindow!
    var last = CACurrentMediaTime()

    func applicationDidFinishLaunching(_ note: Notification) {
        let title = NSTextField(labelWithString: "Tiro alla fune")
        title.font = .systemFont(ofSize: 22, weight: .bold)
        let help = NSTextField(labelWithString: "Blu: metà sinistra della Touch Bar (o tasto A)\nRosso: metà destra (o tasto L)\nMartellate più veloci dell'avversario!")
        help.alignment = .center
        scoreLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        let stack = NSStackView(views: [title, help, scoreLabel])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)

        window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Tiro alla fune"
        window.contentView = stack

        let bar = NSTouchBar()
        bar.defaultItemIdentifiers = [.init("rope")]
        let item = NSCustomTouchBarItem(identifier: .init("rope"))
        item.view = ropeView
        // largo quanto possibile, ma comprimibile così il sistema non nasconde l'elemento
        let wide = ropeView.widthAnchor.constraint(equalToConstant: 1000)
        wide.priority = .defaultLow
        NSLayoutConstraint.activate([wide, ropeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 400)])
        bar.templateItems = [item]
        window.touchBar = bar

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [ropeView] e in
            guard !e.isARepeat else { return nil } // tenere premuto non vale
            switch e.keyCode {
            case 0: ropeView.press(0); return nil  // A
            case 37: ropeView.press(1); return nil // L
            case 49: if ropeView.match.canRestart { ropeView.match = Match() }; return nil // Spazio: rivincita
            default: return e
            }
        }
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let now = CACurrentMediaTime()
                self.ropeView.tick(min(now - self.last, 0.05))
                self.last = now
                let s = "Blu \(self.ropeView.score[0])  –  \(self.ropeView.score[1]) Rosso"
                if self.scoreLabel.stringValue != s { self.scoreLabel.stringValue = s }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }
}

if CommandLine.arguments.contains("--selftest") {
    var m = Match()
    m.pull(1)
    assert(m.rope == 0, "durante il conto alla rovescia non si tira")
    m.time = countdown
    for _ in 0..<toWin - 1 { m.pull(1) }
    m.pull(0)
    assert(m.rope == toWin - 2 && m.winner == nil, "i tiri delle due squadre si annullano")
    m.pull(1); m.pull(1)
    assert(m.winner == 1, "il rosso arriva alla sua linea e vince")
    m.pull(0)
    assert(m.rope == toWin, "dopo la vittoria la corda è ferma")
    assert(!m.canRestart, "la rivincita non parte subito")
    m.time += restartDelay
    assert(m.canRestart, "dopo la pausa si può rigiocare")
    print("selftest ok")
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
