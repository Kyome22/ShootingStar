/*
  FFT.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import Accelerate

typealias FloatPointer = UnsafeMutablePointer<Float>

protocol FFT: AnyObject {
    func computeFFT(_ inAudioData: UnsafePointer<Float>?, count: Int) -> [Float]
}

final class FFTImpl: FFT {
    private var mSpectrumAnalysis: FFTSetup? = nil
    private var mDSPSplitComplex: DSPSplitComplex
    private var mFFTNormFactor: Float
    private var mFFTLength: vDSP_Length
    private var mLog2N: vDSP_Length
    private var kAdjust0DB: Float = 1.5849e-13

    init(maxFramesPerSlice: Int) {
        mFFTNormFactor = 1.0 / Float(2 * maxFramesPerSlice)
        mFFTLength = vDSP_Length(maxFramesPerSlice / 2)
        mLog2N = vDSP_Length(32 - UInt32((UInt32(maxFramesPerSlice) - 1).leadingZeroBitCount))
        mDSPSplitComplex = DSPSplitComplex(
            realp: UnsafeMutablePointer.allocate(capacity: Int(mFFTLength)),
            imagp: UnsafeMutablePointer.allocate(capacity: Int(mFFTLength))
        )
        mSpectrumAnalysis = vDSP_create_fftsetup(mLog2N, FFTRadix(kFFTRadix2))
    }

    deinit {
        vDSP_destroy_fftsetup(mSpectrumAnalysis)
        mDSPSplitComplex.realp.deallocate()
        mDSPSplitComplex.imagp.deallocate()
    }

    func computeFFT(_ inAudioData: UnsafePointer<Float>?, count: Int) -> [Float] {
        let outFFTData = FloatPointer.allocate(capacity: count)
        bzero(outFFTData, size_t(count * MemoryLayout<Float>.size))
        guard let inAudioData, let mSpectrumAnalysis else {
            return Array(repeating: 0, count: count)
        }
        let mFFTFullLength: vDSP_Length = 2 * mFFTLength
        let window = FloatPointer.allocate(capacity: Int(mFFTFullLength))
        vDSP_blkman_window(window, mFFTFullLength, 0)
        let windowAudioData = FloatPointer.allocate(capacity: Int(mFFTFullLength))
        vDSP_vmul(inAudioData, 1, window, 1, windowAudioData, 1, mFFTFullLength)
        windowAudioData.withMemoryRebound(to: DSPComplex.self, capacity: Int(mFFTLength)) { pointer in
            vDSP_ctoz(pointer, 2, &mDSPSplitComplex, 1, mFFTLength)
        }
        vDSP_fft_zrip(mSpectrumAnalysis, &mDSPSplitComplex, 1, mLog2N, FFTDirection(kFFTDirection_Forward))
        vDSP_vsmul(mDSPSplitComplex.realp, 1, &mFFTNormFactor, mDSPSplitComplex.realp, 1, mFFTLength)
        vDSP_vsmul(mDSPSplitComplex.imagp, 1, &mFFTNormFactor, mDSPSplitComplex.imagp, 1, mFFTLength)
        mDSPSplitComplex.imagp[0] = .zero
        vDSP_zvmags(&mDSPSplitComplex, 1, outFFTData, 1, mFFTLength)
        vDSP_vsadd(outFFTData, 1, &kAdjust0DB, outFFTData, 1, mFFTLength)
        var one: Float = 1
        vDSP_vdbcon(outFFTData, 1, &one, outFFTData, 1, mFFTLength, 0)
        // minimum value equal -128dB ???
        return Array<Float>(UnsafeBufferPointer(start: outFFTData, count: count))
    }
}
