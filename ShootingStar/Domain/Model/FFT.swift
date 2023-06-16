/*
  FFT.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  Refer to https://github.com/ooper-shlab/aurioTouch2.0-Swift/blob/master/Classes/FFTHelper.swift
*/

import Accelerate

typealias FloatPointer = UnsafeMutablePointer<Float>

protocol FFT: AnyObject {
    func computeFFT(_ inAudioData: UnsafePointer<Float>) -> [Float]
}

final class FFTImpl: FFT {
    private let fftFullLength: vDSP_Length
    private let fftHalfLength: vDSP_Length
    private var fftNormFactor: Float
    private var dspSplitComplex: DSPSplitComplex
    private let mLog2N: vDSP_Length
    private var fftSetup: FFTSetup?
    private var kAdjust0DB: Float = 1.5849e-13

    init(length: Int) {
        fftFullLength = vDSP_Length(length)
        fftHalfLength = vDSP_Length(length / 2)
        fftNormFactor = 1.0 / Float(2 * length)
        dspSplitComplex = DSPSplitComplex(
            realp: FloatPointer.allocate(capacity: length / 2),
            imagp: FloatPointer.allocate(capacity: length / 2)
        )
        mLog2N = vDSP_Length(log2(Double(length)).rounded())
        fftSetup = vDSP_create_fftsetup(mLog2N, FFTRadix(kFFTRadix2))
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
        dspSplitComplex.realp.deallocate()
        dspSplitComplex.imagp.deallocate()
    }

    func computeFFT(_ inAudioData: UnsafePointer<Float>) -> [Float] {
        guard let fftSetup else {
            return Array<Float>(repeating: 0, count: Int(fftHalfLength))
        }
        let window = FloatPointer.allocate(capacity: Int(fftFullLength))
        vDSP_hann_window(window, fftFullLength, Int32(vDSP_HANN_NORM))
        let windowAudioData = FloatPointer.allocate(capacity: Int(fftFullLength))
        vDSP_vmul(inAudioData, 1, window, 1, windowAudioData, 1, fftFullLength)
        windowAudioData.withMemoryRebound(to: DSPComplex.self, capacity: Int(fftFullLength)) { pointer in
            vDSP_ctoz(pointer, 2, &dspSplitComplex, 1, fftHalfLength)
        }
        vDSP_fft_zrip(fftSetup, &dspSplitComplex, 1, mLog2N, FFTDirection(FFT_FORWARD))
        vDSP_vsmul(dspSplitComplex.realp, 1, &fftNormFactor, dspSplitComplex.realp, 1, fftHalfLength)
        vDSP_vsmul(dspSplitComplex.imagp, 1, &fftNormFactor, dspSplitComplex.imagp, 1, fftHalfLength)
        dspSplitComplex.imagp[0] = .zero
        let outFFTData = FloatPointer.allocate(capacity: Int(fftHalfLength))
        vDSP_zvmags(&dspSplitComplex, 1, outFFTData, 1, fftHalfLength)
        vDSP_vsadd(outFFTData, 1, &kAdjust0DB, outFFTData, 1, fftHalfLength)
        var one: Float = 1
        vDSP_vdbcon(outFFTData, 1, &one, outFFTData, 1, fftHalfLength, 0)
        // minimum value equal -128dB
        return Array<Float>(UnsafeBufferPointer(start: outFFTData, count: Int(fftHalfLength)))
    }
}
