/*
  Point.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/20.
  
*/

import Foundation

struct Point: Hashable, Identifiable {
    let id = UUID()
    let index: Int
    let angle: CGFloat
    let x: Double
    let y: Double
}
