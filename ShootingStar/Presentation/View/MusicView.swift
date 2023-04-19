/*
  MusicView.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import SwiftUI
import Charts

struct MusicView<MVM: MusicViewModel>: View {
    @StateObject private var viewModel: MVM

    init(music: MusicItem) {
        _viewModel = StateObject(wrappedValue: MVM(music: music))
    }

    var body: some View {
        VStack(spacing: 16) {
            Chart {
                ForEach(0 ..< 128, id: \.self) { index in
                    BarMark(x: .value("x", 8 * index),
                            y: .value("p",  128 + viewModel.values[8 * index]),
                            width: .fixed(1))
                }
            }
            .chartXScale(domain: 0 ... SAMPLING_HALF)
            .chartXAxis(.hidden)
            .chartYScale(domain: 0 ... 250)
            .chartYAxis(.hidden)
            .opacity(viewModel.rmsValue)
        }
        .padding(16)
        .navigationTitle(viewModel.music.title ?? "unknown title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.playMusic()
        }
        .onDisappear {
            viewModel.stopMusic()
        }
    }
}

struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        MusicView<PreviewMock.MusicViewModelMock>(music: MusicItem(id: "", assetURL: nil, title: nil))
    }
}
