/*
  MusicViewModel.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import AVFoundation
import Foundation

protocol MusicViewModel: ObservableObject {
    var music: MusicItem { get set }
    var values: [Float] { get set }
    var fftValues: [Float] { get set }
    var rmsValue: Double { get set }
    var graphType: GraphType { get set }
    var dotAngle: Double { get set }
    var points: [Point] { get }

    init(music: MusicItem)
    func playMusic()
    func stopMusic()
}

final class MusicViewModelImpl: MusicViewModel {
    @Published var music: MusicItem
    @Published var values: [Float]
    @Published var fftValues: [Float]
    @Published var rmsValue: Double = 0.3
    @Published var graphType: GraphType = .line
    @Published var dotAngle: Double = 0
    let points: [Point]

    private lazy var playerNode = AVAudioPlayerNode()
    private lazy var audioEngine = AVAudioEngine()
    private let fft = FFTImpl(length: SAMPLING)
    private let signal = SignalImpl()

    init(music: MusicItem) {
        self.music = music
        values = Array<Float>(repeating: 0, count: 128)
        fftValues = Array<Float>(repeating: 0, count: SAMPLING_HALF)
        points = (0 ..< 128).map { i in
            let angle = Double(i) / Double(64) * Double.pi
            return Point(index: 8 * i, angle: angle, x: cos(angle), y: sin(angle))
        }
        audioEngine.attach(playerNode)
    }

    private func calculate(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData else { return }
        let frameLength = UInt(buffer.frameLength)
        let bfr = UnsafePointer(data.pointee)
        Task { @MainActor [weak self] in
            if let self {
                self.values = Array<Float>(UnsafeBufferPointer(start: data.pointee, count: Int(frameLength)))
                self.fftValues = self.fft.computeFFT(bfr)
                self.rmsValue = self.signal.computeRMS(bfr, frameLength: frameLength)
            }
        }
    }

    func playMusic() {
        stopMusic()
        if let assetURl = music.assetURL {
            do {
                let audioFile = try AVAudioFile(forReading: assetURl)
                audioEngine.connect(playerNode,
                                    to: audioEngine.mainMixerNode,
                                    format: audioFile.processingFormat)
                playerNode.installTap(
                    onBus: 0,
                    bufferSize: AVAudioFrameCount(SAMPLING),
                    format: nil
                ) { [weak self] buffer, _ in
                    self?.calculate(buffer)
                }
                playerNode.scheduleFile(audioFile, at: nil)
                try audioEngine.start()
                playerNode.play()
            } catch {
                logput(error.localizedDescription)
            }
        }
    }

    func stopMusic() {
        if audioEngine.isRunning && playerNode.isPlaying {
            playerNode.stop()
            playerNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
    }
}

// MARK: - Preview Mock
extension PreviewMock {
    final class MusicViewModelMock: MusicViewModel {
        @Published var music = MusicItem(id: "", assetURL: nil, title: nil)
        @Published var values: [Float] = []
        @Published var fftValues: [Float] = []
        @Published var rmsValue: Double = 0.3
        @Published var graphType: GraphType = .line
        @Published var dotAngle: Double = 0
        var points = [Point]()

        init(music: MusicItem) {}
        func playMusic() {}
        func stopMusic() {}
    }
}
