/*
  ContentViewModel.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import AVFoundation
import Foundation
import MediaPlayer

let SAMPLING: Int = 2048
let SAMPLING_HALF: Int = 1024

protocol ContentViewModel: ObservableObject {
    var songs: [MusicItem] { get set }
    var values: [Float] { get set }
    var rmsValue: Double { get set }

    init()
    func requestAuthorization()
    func playMusic(song: MusicItem)
    func stopMusic()
}

final class ContentViewModelImpl: ContentViewModel {
    @Published var songs: [MusicItem] = []
    @Published var values: [Float]
    @Published var rmsValue: Double = 0.3

    private lazy var playerNode = AVAudioPlayerNode()
    private lazy var audioEngine = AVAudioEngine()
    private let fft = FFTImpl(maxFramesPerSlice: SAMPLING)
    private let signal = SignalImpl()

    init() {
        values = Array<Float>(repeating: 0, count: SAMPLING_HALF)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logput(error.localizedDescription)
        }
        audioEngine.attach(playerNode)
    }

    private func fetchSongs() {
        guard let songItems = MPMediaQuery.songs().items else { return }
        songs = songItems.map { item in
            return MusicItem(id: item.persistentID.description,
                             assetURL: item.assetURL,
                             title: item.title)
        }
    }

    func requestAuthorization() {
        Task { @MainActor [weak self] in
            let status = await MPMediaLibrary.requestAuthorization()
            switch status {
            case .notDetermined:
                logput("notDetermined")
            case .denied:
                logput("denied")
            case .restricted:
                logput("restricted")
            case .authorized:
                self?.fetchSongs()
            @unknown default:
                fatalError(NOT_IMPLEMENTED)
            }
        }
    }

    private func calculate(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData else { return }
        let frameLength = UInt(buffer.frameLength)
        let bfr = UnsafePointer(data.pointee)
        Task { @MainActor [weak self] in
            if let self {
                self.values = self.fft.computeFFT(bfr, count: SAMPLING_HALF)
                self.rmsValue = self.signal.computeRMS(bfr, frameLength: frameLength)
            }
        }
    }

    func playMusic(song: MusicItem) {
        stopMusic()
        if let assetURl = song.assetURL {
            do {
                let audioFile = try AVAudioFile(forReading: assetURl)
                audioEngine.connect(playerNode,
                                    to: audioEngine.mainMixerNode,
                                    format: audioFile.processingFormat)
                playerNode.installTap(
                    onBus: 0,
                    bufferSize: AVAudioFrameCount(SAMPLING),
                    format: audioFile.processingFormat
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
    final class ContentViewModelMock: ContentViewModel {
        @Published var songs: [MusicItem] = []
        @Published var values: [Float] = []
        @Published var rmsValue: Double = 0.3

        init() {}
        func requestAuthorization() {}
        func playMusic(song: MusicItem) {}
        func stopMusic() {}
    }
}
