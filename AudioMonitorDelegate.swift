//
// AudioMonitorDelegate.swift
// pavisualizer
//
// Created by ArgentWolf on 2020-02-16
//

protocol AudioMonitorDelegate: class {
	
	func receiveSpectrumData(_ data: [Float]);
	
}