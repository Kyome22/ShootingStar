/*
  GraphType.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/20.
  
*/

import Foundation

enum GraphType: String, CaseIterable, Identifiable {
    case line = "Line"
    case bar = "Bar"
    case circle = "Circle"

    var id: String { return rawValue }
}
