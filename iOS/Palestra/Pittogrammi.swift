import SwiftUI

// Pittogrammi degli esercizi: figura di profilo rivolta a destra, in un riquadro 100 × 100
// (stessi disegni della web app)
struct Figura {
    let testa: CGPoint
    let linee: [[CGPoint]]
    let base: [[CGPoint]]

    static let corsa = Figura(testa: P(54, 14), linee: [[P(54, 34), P(48, 58)], [P(48, 58), P(38, 72), P(30, 88)], [P(48, 58), P(62, 70), P(72, 84)], [P(54, 36), P(42, 44), P(34, 36)], [P(54, 36), P(66, 46), P(72, 40)]], base: [[P(10, 96), P(90, 96)]])

    static let generica = Figura(testa: P(50, 18), linee: [[P(50, 34), P(50, 60)], [P(50, 60), P(44, 84), P(42, 96)], [P(50, 60), P(56, 84), P(58, 96)], [P(50, 38), P(40, 54), P(38, 64)], [P(50, 38), P(60, 54), P(62, 64)]], base: [])

    static let esercizi: [String: Figura] = [
        "Leg press": Figura(testa: P(44, 24), linee: [[P(44, 64), P(44, 38)], [P(44, 64), P(70, 56), P(88, 62)], [P(44, 40), P(36, 54), P(38, 62)]], base: [[P(30, 70), P(60, 70)], [P(84, 68), P(96, 68)]]),
        "Chest press": Figura(testa: P(44, 24), linee: [[P(44, 64), P(44, 38)], [P(44, 64), P(66, 64), P(66, 84)], [P(44, 40), P(64, 40), P(84, 40)]], base: [[P(30, 70), P(60, 70)]]),
        "Shoulder press": Figura(testa: P(44, 24), linee: [[P(44, 64), P(44, 38)], [P(44, 64), P(66, 64), P(66, 84)], [P(44, 40), P(32, 28), P(30, 12)], [P(44, 40), P(58, 28), P(62, 12)]], base: [[P(30, 70), P(60, 70)]]),
        "Seated row": Figura(testa: P(44, 24), linee: [[P(44, 64), P(44, 38)], [P(44, 64), P(66, 64), P(66, 84)], [P(44, 40), P(34, 46), P(40, 54)]], base: [[P(30, 70), P(60, 70)], [P(62, 44), P(78, 44)]]),
        "Lat machine": Figura(testa: P(50, 20), linee: [[P(50, 56), P(50, 34)], [P(50, 56), P(46, 76), P(44, 94)], [P(50, 56), P(56, 76), P(58, 94)], [P(50, 36), P(34, 44), P(38, 20)], [P(50, 36), P(66, 44), P(62, 20)]], base: [[P(26, 6), P(74, 6)]]),
        "Leg curl": Figura(testa: P(20, 44), linee: [[P(30, 50), P(52, 50)], [P(52, 50), P(72, 50), P(84, 38)], [P(32, 50), P(26, 60), P(36, 60)]], base: [[P(14, 58), P(90, 58)]]),
        "Addominali": Figura(testa: P(36, 58), linee: [[P(66, 78), P(44, 66)], [P(66, 78), P(80, 64), P(90, 80)], [P(44, 66), P(38, 54), P(46, 50)]], base: [[P(14, 82), P(92, 82)]]),
    ]

    static func per(_ esercizio: String) -> Figura { esercizi[esercizio] ?? generica }
}

private func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

struct Pittogramma: View {
    let figura: Figura
    var lato: CGFloat = 44

    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 100
            func tratto(_ punti: [CGPoint]) -> Path {
                var p = Path()
                p.addLines(punti.map { CGPoint(x: $0.x * k, y: $0.y * k) })
                return p
            }
            let stileBase = StrokeStyle(lineWidth: 4 * k, lineCap: .round, lineJoin: .round)
            let stile = StrokeStyle(lineWidth: 6 * k, lineCap: .round, lineJoin: .round)
            for l in figura.base { ctx.stroke(tratto(l), with: .style(.secondary.opacity(0.6)), style: stileBase) }
            for l in figura.linee { ctx.stroke(tratto(l), with: .style(.tint), style: stile) }
            let t = figura.testa
            ctx.stroke(Path(ellipseIn: CGRect(x: (t.x - 7) * k, y: (t.y - 7) * k, width: 14 * k, height: 14 * k)),
                       with: .style(.tint), style: stile)
        }
        .frame(width: lato, height: lato)
        .accessibilityHidden(true)
    }
}
