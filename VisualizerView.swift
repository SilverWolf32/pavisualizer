import Foundation
import CursesUI

class VisualizerView: InputResponsiveView, AudioMonitorDelegate {
	
	private var initializing = true
	private var initColumn = 0
	private var animationQueue: DispatchQueue? = nil
	private var audioMonitor: AudioMonitor? = nil
	
	private var heights: [Int] = [];
	
	override func draw(refresh doRefresh: Bool = true) {
		if animationQueue == nil {
			animationQueue = DispatchQueue.global(qos: .userInteractive)
			
			self.audioMonitor = AudioMonitor()
			self.audioMonitor?.startListening()
			
			animationQueue!.async { [unowned self] in
				while (true) {
					self.initColumn += 1
					if (self.initColumn >= self.width) {
						self.initializing = false
						return
					} else {
						self.write(".", atPoint: (self.height - 1, self.initColumn))
						self.refresh()
					}
					usleep(1_000_000 / UInt32(self.width)) // 1s total
				}
			}
			return
		}
		
		if !initializing {
			self.clear()
			for i in 0..<heights.count {
				let h = abs(heights[i]) + 1
				for j in 0..<h {
					self.write(".", atPoint: (self.height - 1 - j, i))
				}
			}
		}
		
		if (doRefresh) {
			self.refresh()
		}
	}
	
	func receiveSpectrumData(_ data: [Float]) {
		// let scalingFactor = Float(self.height)
		let scalingFactor = Float(1.0)
		
		heights.removeAll()
		heights.reserveCapacity(self.width)
		
		for i in 0..<self.width {
			let dataIndex = Int((Double(i) / Double(self.width)) * Double(data.count))
			let dataPoint = data[dataIndex]
			let h = Int(dataPoint * scalingFactor)
			heights.append(h)
		}
		
		self.draw()
	}
	
}
