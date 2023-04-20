/*
  ContentViewModel.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/


import Foundation
import MediaPlayer

let SAMPLING: Int = 2048
let SAMPLING_HALF: Int = 1024

protocol ContentViewModel: ObservableObject {
    var searchText: String { get set }
    var musics: [MusicItem] { get set }

    init()
    func requestAuthorization()
}

final class ContentViewModelImpl: ContentViewModel {
    @Published var searchText: String = ""
    @Published var musics: [MusicItem] = []

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logput(error.localizedDescription)
        }
    }

    private func fetchSongs() {
        guard let musicItems = MPMediaQuery.songs().items else { return }
        musics = musicItems.map { item in
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
}

// MARK: - Preview Mock
extension PreviewMock {
    final class ContentViewModelMock: ContentViewModel {
        @Published var searchText: String = ""
        @Published var musics: [MusicItem] = []

        init() {}
        func requestAuthorization() {}
    }
}
