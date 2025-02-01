import AVFoundation

class BrownNoiseGenerator {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: 2)
    private let format: AVAudioFormat
    private let bufferSize: AVAudioFrameCount = 1024
    private var lastValueLeft: Float = 0.0
    private var lastValueRight: Float = 0.0
    private var noiseFluctuationRange: Float = 0
    private var isPlaying = false

    public var errorMessage: String?

    init() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Error setting up AVAudioSession: \(error)")
        }
        #endif

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        setupEQ()

        engine.attach(player)
        engine.attach(eq)
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)
    }
    
    func start() {
        do {
            try engine.start()
            isPlaying = true
            loadBuffers()
            player.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stop() {
        isPlaying = false
    }

    private func setupEQ() {
        let bassBand = eq.bands[0]
        bassBand.filterType = .lowShelf
        bassBand.frequency = 100
        bassBand.gain = 10
        bassBand.bypass = false

        let trebleBand = eq.bands[1]
        trebleBand.filterType = .highShelf
        trebleBand.frequency = 5000
        trebleBand.gain = -10
        trebleBand.bypass = false
    }
    
    private func loadBuffers() {
        guard isPlaying else {
            engine.stop()
            return
        }

        player.scheduleBuffer(createBuffer(), completionHandler: {
            self.loadBuffers()
        })

        for _ in 0..<50 {
            player.scheduleBuffer(createBuffer())
        }
    }
    
    private func createBuffer() -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize)!
        buffer.frameLength = bufferSize
        let audioBufferL = buffer.floatChannelData![0]
        let audioBufferR = buffer.floatChannelData![1]

        // Fade in
        if noiseFluctuationRange < 0.2 {
            noiseFluctuationRange += 0.01
        }
        
        for i in 0..<Int(bufferSize) {
            let whiteL = Float.random(in: -noiseFluctuationRange...noiseFluctuationRange)
            let whiteR = Float.random(in: -noiseFluctuationRange...noiseFluctuationRange)

            lastValueLeft = lastValueLeft + whiteL
            lastValueRight = lastValueRight + whiteR

            lastValueLeft = min(max(lastValueLeft, -1.0), 1.0)
            lastValueRight = min(max(lastValueRight, -1.0), 1.0)

            audioBufferL[i] = lastValueLeft
            audioBufferR[i] = lastValueRight
        }

        return buffer
    }
}
