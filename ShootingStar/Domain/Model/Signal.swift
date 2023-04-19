/*
  Signal.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import Accelerate

protocol Signal: AnyObject {
    func computeRMS(_ inAudioData: UnsafePointer<Float>, frameLength: vDSP_Length) -> Double
}

final class SignalImpl: Signal {
    init() {}

    // Root Mean Square
    func computeRMS(_ inAudioData: UnsafePointer<Float>, frameLength: vDSP_Length) -> Double {
        var value: Float = 0
        vDSP_measqv(inAudioData, 1, &value, frameLength)
        let db = 10 * log10f(value) + 160 - 120
        var adjustedValue = 0.3 + db / Float(40 / 0.3)
        if adjustedValue < 0.3 {
            adjustedValue = 0.3
        } else if 0.6 < adjustedValue {
            adjustedValue = 0.6
        }
        return Double(adjustedValue)
    }
}
