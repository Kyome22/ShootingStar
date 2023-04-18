/*
  ContentViewModel.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import AVFoundation
import Foundation
import MediaPlayer

protocol ContentViewModel: ObservableObject {
    var songs: [MusicItem] { get set }
    var values: [Float] { get set }

    init()
    func requestAuthorization()
    func playMusic(song: MusicItem)
    func stopMusic()
}

final class ContentViewModelImpl: ContentViewModel {
    @Published var songs: [MusicItem] = []
    @Published var values: [Float]

    private lazy var playerNode = AVAudioPlayerNode()
    private lazy var audioEngine = AVAudioEngine()
    private let fft = FFTImpl(maxFramesPerSlice: 4096)

    init() {
        values = Array<Float>(repeating: 0, count: 2048)
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

    private func callFFT(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData else { return }
        let bfr = UnsafePointer(data.pointee)
        Task { @MainActor [weak self] in
            if let self {
                self.values = self.fft.computeFFT(bfr)
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
                    bufferSize: 4096,
                    format: audioFile.processingFormat
                ) { [weak self] buffer, _ in
                    self?.callFFT(buffer)
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

        init() {}
        func requestAuthorization() {}
        func playMusic(song: MusicItem) {}
        func stopMusic() {}
    }
}
