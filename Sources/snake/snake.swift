import SwiftUI
import AppKit

let N = 17

func pixelDigit(number: Int) -> [UInt8] {
    switch number {
    case 0:
        [
            1, 1, 1,
            1, 0, 1,
            1, 0, 1,
            1, 0, 1,
            1, 1, 1
        ]
    case 1:
        [
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1
        ]
    case 2:
        [
            1, 1, 1,
            0, 0, 1,
            1, 1, 1,
            1, 0, 0,
            1, 1, 1
        ]
    case 3:
        [
            1, 1, 1,
            0, 0, 1,
            1, 1, 1,
            0, 0, 1,
            1, 1, 1
        ]   
    case 4:
        [
            1, 0, 1,
            1, 0, 1,
            1, 1, 1,
            0, 0, 1,
            0, 0, 1
        ]
    case 5:
        [
            1, 1, 1,
            1, 0, 0,
            1, 1, 1,
            0, 0, 1,
            1, 1, 1
        ]
    case 6:
        [
            1, 1, 1,
            1, 0, 0,
            1, 1, 1,
            1, 0, 1,
            1, 1, 1
        ]
    case 7:
        [
            1, 1, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1
        ]
    case 8:
        [
            1, 1, 1,
            1, 0, 1,
            1, 1, 1,
            1, 0, 1,
            1, 1, 1
        ]
    case 9:
        [
            1, 1, 1,
            1, 0, 1,
            1, 1, 1,
            0, 0, 1,
            1, 1, 1
        ]
    default:
        [
            0, 0, 0,
            0, 0, 0,
            0, 0, 0,
            0, 0, 0,
            0, 0, 0
        ]
    }
}

struct Pixel {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8 = 255
}

enum MoveDir {
    case left
    case up
    case right
    case down
}

@main
struct PixelApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
    }
}

struct ContentView: View {
    @State private var engine = Engine()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            if let cgImage = engine.cgImage {
                Image(cgImage, scale: 1.0, label: Text("Texture"))
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(1, contentMode: .fit)
                    .padding()
            }
        }
        .frame(minWidth: 300, minHeight: 300)
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress { press in
            if engine.handleKeyPress(press) {
                return .handled
            }
            return .ignored
        }
        .onAppear {
            isFocused = true
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            engine.stop()
        }
    }
}

@MainActor
@Observable
final class Engine {
    var grid: [Int] = Array(repeating: 0, count: N * N)
    var pixels: [Pixel] = Array(repeating: Pixel(r: 0, g: 0, b: 0), count: N * N)

    var snakeSize = 0
    var snakeHead = (N / 2) + N * (N / 2)
    var moveDir: MoveDir = .left
    var moveDirApplied: MoveDir = .left
    var doFoodExists = false
    var isGameOver = false

    private var timerTask: Task<Void, Never>?

    init() {
        resetGame()
        setupTimer()
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    // Обработчик нажатий из SwiftUI
    func handleKeyPress(_ press: KeyPress) -> Bool {
        if isGameOver {
            resetGame()
            return true
        }

        switch press.key {
        case .leftArrow:
            moveDir = .left
            return true
        case .upArrow:
            moveDir = .up
            return true
        case .rightArrow:
            moveDir = .right
            return true
        case .downArrow:
            moveDir = .down
            return true
        default:
            return false
        }
    }

    private func setupTimer() {
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self else { break }
                self.tick()
            }
        }
    }

    private func tick() {
        if isGameOver {
            return
        }

        if !doFoodExists && Int.random(in: 0...1) == 1 {
            let foodIdx = Int.random(in: 0...(N * N) - (snakeSize + 1))
            var idx = 0
            for i in 0..<(N * N) {
                if grid[i] == 0 {
                    if foodIdx == idx {
                        grid[i] = -1
                        doFoodExists = true
                        break
                    }
                    idx += 1
                }
            }
        }

        moveDir = switch moveDir {
            case .left:
                moveDirApplied == .right ? moveDirApplied : .left
            case .up:
                moveDirApplied == .down ? moveDirApplied : .up
            case .right:
                moveDirApplied == .left ? moveDirApplied : .right
            case .down:
                moveDirApplied == .up ? moveDirApplied : .down
        }

        moveDirApplied = moveDir

        let headRow = snakeHead / N
        let headCollumn = snakeHead % N 

        snakeHead = switch moveDir {
            case .left:
                snakeHead - 1
            case .up:
                snakeHead - N
            case .right:
                snakeHead + 1
            case .down:
                snakeHead + N
        }

        if snakeHead < 0 || snakeHead >= (N * N) || ((snakeHead / N != headRow) && (snakeHead % N != headCollumn)) || grid[snakeHead] > 0 {
            gameOver()
            return
        }

        if grid[snakeHead] == -1 {
            doFoodExists = false
            snakeSize += 1
            for i in 0..<(N * N) {
                if grid[i] > 0 {
                    grid[i] += 1
                }
            }
        }

        grid[snakeHead] = snakeSize + 2

        for i in 0..<(N * N) {
            if grid[i] > 0 {
                grid[i] -= 1
            }
        }

        updatePixels()
    }

    private func updatePixels() {
        for i in 0..<(N * N) {
            switch grid[i] {
            case -1:
                pixels[i] = Pixel(r: 255, g: 0, b: 0)
            case 0:
                pixels[i] = Pixel(r: 0, g: 0, b: 0)
            case snakeSize + 1:
                pixels[i] = Pixel(r: 0, g: 255, b: 0)
            default:
                pixels[i] = Pixel(r: 255, g: 255, b: 255)
            }
        }
        
        updateLabel()
    }

    private func updateLabel() {
        var label = snakeSize
        var digitPos = 3

        repeat {
            let digit = pixelDigit(number: label % 10)
            label /= 10

            for row in 0...4 {
                for collumn in 0...2 {
                    let pixelIdx = 1 + (row + 1) * N + digitPos * 4 + collumn
                    if pixels[pixelIdx].r == 0 && pixels[pixelIdx].g == 0 && pixels[pixelIdx].b == 0 {
                        pixels[pixelIdx] = digit[row * 3 + collumn] == 1 ? Pixel(r: 50, g: 50, b: 50) : Pixel(r: 0, g: 0, b: 0)
                    }
                }
            }

            digitPos -= 1
        } while digitPos >= 0 && label > 0
    }

    private func resetGame() {
        switch Int.random(in: 0...3) {
            case 0:
                moveDir = .left
            case 1:
                moveDir = .up
            case 2:
                moveDir = .right
            case 3:
                moveDir = .down
            default:
                break
        }
        moveDirApplied = moveDir

        for i in 0..<(N * N) {
            grid[i] = 0
        }

        snakeHead = (N / 2) + N * (N / 2)

        grid[snakeHead] = 1

        snakeSize = 0

        doFoodExists = false

        updatePixels()

        isGameOver = false
    }

    private func gameOver() {
        isGameOver = true

        for i in 0..<(N * N) {
            pixels[i] = Pixel(r: 0, g: 0, b: 0)
        }

        updateLabel()

        for i in 0..<(N * N) {
            if pixels[i].r == 0 && pixels[i].g == 0 && pixels[i].b == 0 {
                let fill: UInt8 = i % 2 == 0 ? 25 : 50
                pixels[i] = Pixel(r: fill, g: fill, b: 0)
            } else {
                pixels[i] = Pixel(r: 0, g: 255, b: 0)
            }
        }
    }

    var cgImage: CGImage? {
        let data = pixels.withUnsafeBytes { Data($0) }
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }

        return CGImage(
            width: N,
            height: N,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: N * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}