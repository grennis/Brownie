import AVFoundation

class BrownNoiseGenerator {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let bufferSize: AVAudioFrameCount = 1024
    private var lastValueLeft: Float = 0.0
    private var lastValueRight: Float = 0.0
    private var smoothFactor: Float = 1 // Higher = smoother (stronger low frequencies)

    init() {
        configureAudioSession()
        setupAudioEngine()
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Error setting up AVAudioSession: \(error)")
        }
        #endif
    }

    private func setupAudioEngine() {
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.play()
            preloadBuffers(sampleRate: Float(sampleRate), format: format)
        } catch {
            print("Error starting engine: \(error)")
        }
    }

    private func preloadBuffers(sampleRate: Float, format: AVAudioFormat) {
        let queue = DispatchQueue.global(qos: .userInitiated)
        queue.async { [weak self] in
            guard let self = self else { return }

            for _ in 0..<5 {
                let buffer = self.createDeepBrownNoiseBuffer(sampleRate: sampleRate, format: format)
                self.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            }

            self.scheduleNextBuffer(sampleRate: sampleRate, format: format)
        }
    }

    private func scheduleNextBuffer(sampleRate: Float, format: AVAudioFormat) {
        let buffer = createDeepBrownNoiseBuffer(sampleRate: sampleRate, format: format)
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            self?.scheduleNextBuffer(sampleRate: sampleRate, format: format)
        })
    }

    private func createDeepBrownNoiseBuffer(sampleRate: Float, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize)!
        buffer.frameLength = bufferSize
        let audioBufferL = buffer.floatChannelData![0]
        let audioBufferR = buffer.floatChannelData![1]

        for i in 0..<Int(bufferSize) {
            let whiteL = Float.random(in: -0.01...0.01) // Even smaller step size for smoother noise
            let whiteR = Float.random(in: -0.01...0.01)

            lastValueLeft = smoothFactor * lastValueLeft + whiteL
            lastValueRight = smoothFactor * lastValueRight + whiteR

            // Allow more range to create a deeper tone
            lastValueLeft = min(max(lastValueLeft, -1.0), 1.0)
            lastValueRight = min(max(lastValueRight, -1.0), 1.0)

            audioBufferL[i] = lastValueLeft
            audioBufferR[i] = lastValueRight
        }

        return buffer
    }
}

// Start generating deep stereo brown noise
//let generator = StereoDeepBrownNoiseGenerator()
//RunLoop.main.run()
