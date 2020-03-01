//
// AudioMonitorDelegate.swift
// pavisualizer
//
// Created by ArgentWolf on 2020-02-16
//

protocol AudioMonitorDelegate: class {
	
	func receiveWaveformData(_ data: [UInt8])
	func receiveSpectrumData(_ data: [Float])
	func shouldReceiveFFT() -> Bool
	
}

// default implementations
extension AudioMonitorDelegate {
	func receiveWaveformData(_ data: [UInt8]) {
		
	}
	func receiveSpectrumData(_ data: [Float]) {
		
	}
}
