//
//  ContentView.swift
//  ShootingStar
//
//  Created by Takuto Nakamura on 2023/04/19.
//

import SwiftUI

struct ContentView<CVM: ContentViewModel>: View {
    @StateObject private var viewModel: CVM

    init() {
        _viewModel = StateObject(wrappedValue: CVM())
    }

    var body: some View {
        VStack(spacing: 8) {
            List(viewModel.songs) { song in
                HStack(alignment: .top) {
                    Image(systemName: "music.note.list")
                    VStack(alignment: .leading) {
                        Text(song.title ?? "unknown title")
                            .font(.body)
                        Text(verbatim: song.assetURL?.relativePath ?? "unknown url")
                            .font(.callout)
                            .truncationMode(.middle)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        viewModel.playMusic(song: song)
                    }
                }
            }
            .onAppear {
                viewModel.requestAuthorization()
            }
            Button {
                viewModel.stopMusic()
            } label: {
                Image(systemName: "stop.circle")
                    .imageScale(.large)
            }
        }
        .padding(16)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView<PreviewMock.ContentViewModelMock>()
    }
}
