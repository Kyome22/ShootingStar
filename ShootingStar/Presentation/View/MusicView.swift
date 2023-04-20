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
            GeometryReader { geometry in
                let length = geometry.size.minLength
                ZStack {
                    switch viewModel.graphType {
                    case .line:
                        Chart {
                            let lineWidth = 2.0 * viewModel.rmsValue
                            ForEach(0 ..< 128, id: \.self) { index in
                                LineMark(x: .value("x", index),
                                         y: .value("y", viewModel.values[index]))
                                .lineStyle(StrokeStyle(lineWidth: lineWidth))
                                .interpolationMethod(.cardinal)
                            }
                            .foregroundStyle(.linearGradient(colors: [.green, .yellow, .red],
                                                             startPoint: .bottom,
                                                             endPoint: .top))
                            .alignsMarkStylesWithPlotArea()
                        }
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .aspectRatio(1.6, contentMode: .fit)
                    case .bar:
                        Chart {
                            ForEach(0 ..< 128, id: \.self) { index in
                                BarMark(x: .value("x", 8 * index),
                                        y: .value("y", 128 + viewModel.fftValues[8 * index]),
                                        width: .fixed(1),
                                        stacking: .center)
                            }
                            .foregroundStyle(.linearGradient(colors: [.red, .yellow, .green, .yellow, .red],
                                                             startPoint: .top,
                                                             endPoint: .bottom))
                            .alignsMarkStylesWithPlotArea()
                        }
                        .chartXScale(domain: 0 ... SAMPLING_HALF)
                        .chartYScale(domain: -64 ... 64)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .aspectRatio(1.6, contentMode: .fit)
                    case .circle:
                        Chart {
                            Plot {
                                ForEach(viewModel.points) { point in
                                    let value = 1.0 + (Double(viewModel.fftValues[point.index]) / 128.0)
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
                        .frame(width: length, height: length)
                        Circle()
                            .frame(width: 0.6 * length, height: 0.6 * length)
                            .foregroundColor(.secondary)
                            .scaleEffect(viewModel.rmsValue)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Picker("", selection: $viewModel.graphType) {
                ForEach(GraphType.allCases) { graphType in
                    Text(graphType.rawValue).tag(graphType)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(alignment: .center)
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
