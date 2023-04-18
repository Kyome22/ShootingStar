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

    init()
    func requestAuthorization()
    func playMusic(song: MusicItem)
    func stopMusic()
}

final class ContentViewModelImpl: ContentViewModel {
    @Published var songs: [MusicItem] = []
    private var audioPlayer: AVAudioPlayer?

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logput(error.localizedDescription)
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

    private func fetchSongs() {
        guard let songItems = MPMediaQuery.songs().items else { return }
        songs = songItems.map { item in
            return MusicItem(id: item.persistentID.description,
                             assetURL: item.assetURL,
                             title: item.title)
        }
    }

    func playMusic(song: MusicItem) {
        if let assetURl = song.assetURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: assetURl)
                audioPlayer?.play()
            } catch {
                logput(error.localizedDescription)
            }
        }
    }

    func stopMusic() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
    }
}

// MARK: - Preview Mock
extension PreviewMock {
    final class ContentViewModelMock: ContentViewModel {
        @Published var songs: [MusicItem] = []

        init() {}
        func requestAuthorization() {}
        func playMusic(song: MusicItem) {}
        func stopMusic() {}
    }
}
