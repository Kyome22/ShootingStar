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
            Spacer()
            switch viewModel.graphType {
            case .horizontal:
                Chart {
                    ForEach(0 ..< 128, id: \.self) { index in
                        BarMark(x: .value("x", 8 * index),
                                y: .value("p",  128 + viewModel.values[8 * index]),
                                width: .fixed(1))
                    }
                    .foregroundStyle(.linearGradient(colors: [.green, .yellow, .red],
                                                     startPoint: .bottom,
                                                     endPoint: .top))
                    .alignsMarkStylesWithPlotArea()
                }
                .chartXScale(domain: 0 ... SAMPLING_HALF)
                .chartYScale(domain: 0 ... 128)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .opacity(viewModel.rmsValue)
                .aspectRatio(1, contentMode: .fit)
            case .circle:
                ZStack {
                    Chart {
                        Plot {
                            ForEach(viewModel.points) { point in
                                let value = 1.0 + (Double(viewModel.values[point.index]) / 128.0)
                                PointMark(x: .value("x", point.x), y: .value("y", point.y))
                                    .symbol(Rect(angle: point.angle, length: value))
                                    .foregroundStyle(Color(hue: value, saturation: 1, brightness: 1))
                            }
                        }
                    }
                    .chartXScale(domain: -2 ... 2)
                    .chartYScale(domain: -2 ... 2)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .aspectRatio(1, contentMode: .fit)
                    Circle()
                        .frame(width: 200, height: 200)
                        .foregroundColor(.secondary)
                        .scaleEffect(viewModel.rmsValue)
                }
            }
            Spacer()
            Picker("", selection: $viewModel.graphType) {
                ForEach(GraphType.allCases) { graphType in
                    Text(graphType.rawValue).tag(graphType)
                }
            }
            .pickerStyle(.segmented)
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

struct Rect: ChartSymbolShape {
    let angle: CGFloat
    let length: CGFloat

    init(angle: CGFloat, length: CGFloat) {
        self.angle = angle
        self.length = length
    }

    var perceptualUnitRect: CGRect {
        return CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    func path(in rect: CGRect) -> Path {
        return Path(CGRect(x: 0, y: -1, width: 100 * length, height: 2))
            .applying(.init(rotationAngle: -angle))
            .applying(.init(translationX: rect.midX, y: rect.midY))
    }
}
