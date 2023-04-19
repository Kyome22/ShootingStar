/*
  CoreGraphics.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/20.
  
*/

import CoreGraphics

extension CGSize {
    var minLength: CGFloat {
        return min(self.width, self.height)
    }
}
