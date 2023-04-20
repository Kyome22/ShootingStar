//
//  RectSymbol.swift
//  ShootingStar
//
//  Created by ky0me22 on 2023/04/20.
//

import SwiftUI
import Charts

struct RectSymbol: ChartSymbolShape {
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
