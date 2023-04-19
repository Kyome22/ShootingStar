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
        NavigationView {
            List(viewModel.musics) { music in
                NavigationLink(destination: MusicView<MusicViewModelImpl>(music: music)) {
                    HStack(alignment: .top) {
                        Image(systemName: "music.note.list")
                        VStack(alignment: .leading) {
                            Text(music.title ?? "unknown title")
                                .font(.body)
                        }
                    }
                }
            }
            .navigationBarTitle("Musics")
            .padding(.bottom, 8)
        }
        .onAppear {
            viewModel.requestAuthorization()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView<PreviewMock.ContentViewModelMock>()
    }
}
