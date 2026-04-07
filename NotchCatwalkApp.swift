import SwiftUI
import Cocoa

// MARK: - App Entry

@main
struct NotchCatwalkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel?
    let state = CatwalkState()
    var mouseMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createPanel()
        startMouseTracking()
    }

    func createPanel() {
        guard let screen = NSScreen.main else { return }

        let notchHeight = screen.safeAreaInsets.top
        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = notchHeight + 40

        let origin = NSPoint(
            x: screen.frame.midX - panelWidth / 2,
            y: screen.frame.maxY - panelHeight
        )

        let swiftUIView = NotchCatwalkView(state: state, notchHeight: notchHeight)
        let hostingView = NSHostingView(rootView: swiftUIView)
        hostingView.frame = NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight))

        let newPanel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.level = .statusBar
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.isMovable = false
        newPanel.ignoresMouseEvents = true
        newPanel.sharingType = .readOnly  // Allow screen recording to capture this window
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        newPanel.contentView = hostingView
        newPanel.orderFront(nil)
        panel = newPanel
    }

    func startMouseTracking() {
        guard let screen = NSScreen.main else { return }
        let notchHeight = screen.safeAreaInsets.top

        let zoneWidth: CGFloat = 340
        let zoneHeight: CGFloat = notchHeight + 50
        let zoneRect = NSRect(
            x: screen.frame.midX - zoneWidth / 2,
            y: screen.frame.maxY - zoneHeight,
            width: zoneWidth,
            height: zoneHeight
        )

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouse = NSEvent.mouseLocation
            let isNear = zoneRect.contains(mouse)

            DispatchQueue.main.async {
                if isNear && !self.state.isExpanded {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                        self.state.isExpanded = true
                    }
                } else if !isNear && self.state.isExpanded {
                    withAnimation(.spring(response: 0.38, dampingFraction: 1.0)) {
                        self.state.isExpanded = false
                    }
                }
            }
        }
    }
}

// MARK: - State

@Observable
final class CatwalkState: @unchecked Sendable {
    var progress: CGFloat = 0
    var isExpanded = false
    var wobble: CGFloat = 0
    var stepBounce: CGFloat = 0  // Walking bounce
    var tailWag: CGFloat = 0
    // Trail particles: (x, y, opacity, id)
    var particles: [(x: CGFloat, y: CGFloat, opacity: CGFloat, id: Int)] = []
    var nextParticleID = 0
}

// MARK: - Notch Path

struct NotchPathInfo {
    let notchWidth: CGFloat = 200
    let notchHeight: CGFloat

    var waypoints: [CGPoint] {
        let hw = notchWidth / 2
        let m: CGFloat = 30

        return [
            CGPoint(x: -(hw + m), y: 2),
            CGPoint(x: -(hw + m), y: notchHeight - 2),
            CGPoint(x: -hw, y: notchHeight - 2),
            CGPoint(x: -hw, y: notchHeight + 18),
            CGPoint(x: hw, y: notchHeight + 18),
            CGPoint(x: hw, y: notchHeight - 2),
            CGPoint(x: (hw + m), y: notchHeight - 2),
            CGPoint(x: (hw + m), y: 2),
        ]
    }

    var segmentLengths: [CGFloat] {
        let pts = waypoints
        return (0..<pts.count - 1).map { i in
            hypot(pts[i + 1].x - pts[i].x, pts[i + 1].y - pts[i].y)
        }
    }

    var totalLength: CGFloat { segmentLengths.reduce(0, +) }

    func positionAndAngle(at progress: CGFloat) -> (CGPoint, CGFloat) {
        let pts = waypoints
        let lengths = segmentLengths
        let total = totalLength

        let t: CGFloat
        let reversed: Bool
        if progress <= 0.5 {
            t = progress * 2
            reversed = false
        } else {
            t = (1 - progress) * 2
            reversed = true
        }

        let targetDist = t * total
        var accumulated: CGFloat = 0

        for i in 0..<lengths.count {
            let segLen = lengths[i]
            if accumulated + segLen >= targetDist {
                let segProgress = (targetDist - accumulated) / segLen
                let from = pts[i]
                let to = pts[i + 1]
                let pos = CGPoint(
                    x: from.x + (to.x - from.x) * segProgress,
                    y: from.y + (to.y - from.y) * segProgress
                )
                let dx = reversed ? (from.x - to.x) : (to.x - from.x)
                return (pos, dx > 0 ? 1 : -1)
            }
            accumulated += segLen
        }

        return (pts.last ?? .zero, 1)
    }
}


// MARK: - View

struct NotchCatwalkView: View {
    var state: CatwalkState
    let notchHeight: CGFloat

    private let catSize: CGFloat = 16
    private let panelWidth: CGFloat = 340

    private let closedWidth: CGFloat = 200
    private let expandedWidth: CGFloat = 300
    private let closedExtraHeight: CGFloat = -6
    private let expandedExtraHeight: CGFloat = 24

    var body: some View {
        let currentWidth = state.isExpanded ? expandedWidth : closedWidth
        let currentHeight = notchHeight + (state.isExpanded ? expandedExtraHeight : closedExtraHeight)
        let cornerRadius: CGFloat = state.isExpanded ? 18 : 0
        let pathInfo = NotchPathInfo(notchHeight: notchHeight)
        let (pos, direction) = pathInfo.positionAndAngle(at: state.progress)

        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if state.isExpanded {
                    // Trailing sparkle particles
                    ForEach(state.particles, id: \.id) { p in
                        Text("✦")
                            .font(.system(size: 6))
                            .foregroundStyle(.white.opacity(p.opacity))
                            .position(x: currentWidth / 2 + p.x, y: p.y)
                    }

                    // Cat with walk bounce + tilt on slopes
                    CatCharacter(
                        direction: direction,
                        bounce: state.stepBounce,
                        tailWag: state.tailWag
                    )
                    .frame(width: catSize + 4, height: catSize + 4)
                    .position(
                        x: currentWidth / 2 + pos.x,
                        y: pos.y + state.stepBounce
                    )
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            .frame(width: currentWidth, height: currentHeight)
            .background(.black)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: 0
                )
            )
            .shadow(
                color: state.isExpanded ? .black.opacity(0.4) : .clear,
                radius: 8
            )

            Spacer(minLength: 0)
        }
        .frame(width: panelWidth, height: notchHeight + 40)
        .task {
            await patrolLoop()
        }
    }

    private func patrolLoop() async {
        var progress: CGFloat = 0
        let speed: CGFloat = 0.003
        var tick: Int = 0
        let pathInfo = NotchPathInfo(notchHeight: notchHeight)

        while !Task.isCancelled {
            progress += speed
            if progress > 1 { progress -= 1 }
            tick += 1

            state.progress = progress

            // Walk bounce: quick sine wave
            state.stepBounce = sin(CGFloat(tick) * 0.5) * 1.5

            // Tail wag
            state.tailWag = sin(CGFloat(tick) * 0.3) * 8

            // Spawn sparkle particle every 6 ticks
            if tick % 6 == 0 {
                let currentWidth = state.isExpanded ? expandedWidth : closedWidth
                let (pos, _) = pathInfo.positionAndAngle(at: progress)
                state.particles.append((
                    x: pos.x + CGFloat.random(in: -3...3),
                    y: pos.y + CGFloat.random(in: -2...2),
                    opacity: 0.7,
                    id: state.nextParticleID
                ))
                state.nextParticleID += 1
                _ = currentWidth // suppress warning
            }

            // Fade out particles
            state.particles = state.particles.compactMap { p in
                let newOpacity = p.opacity - 0.03
                if newOpacity <= 0 { return nil }
                return (p.x, p.y, newOpacity, p.id)
            }

            do {
                try await Task.sleep(for: .milliseconds(30))
            } catch {
                return
            }
        }
    }
}

// MARK: - Cat Character

struct CatCharacter: View {
    let direction: CGFloat
    let bounce: CGFloat
    let tailWag: CGFloat

    var body: some View {
        ZStack {
            // Tail (behind cat)
            Text("〰")
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.6))
                .rotationEffect(.degrees(Double(tailWag)))
                .offset(x: direction > 0 ? -8 : 8, y: -1)

            // Cat emoji
            Text("🐈")
                .font(.system(size: 14))
        }
        .scaleEffect(x: -direction, y: 1)
        .rotationEffect(.degrees(Double(bounce) * 1.5))
    }
}
