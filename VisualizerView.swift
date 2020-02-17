import Foundation
import CursesUI

class VisualizerView: InputResponsiveView, AudioMonitorDelegate {
	
	private var initializing = true
	private var initColumn = 0
	private var animationQueue: DispatchQueue? = nil
	
	private var heights: [Int] = [];
	
	override func draw(refresh doRefresh: Bool = true) {
		if animationQueue == nil {
			animationQueue = DispatchQueue.global(qos: .userInteractive)
			
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
	
	func receiveSpectrumData(_ dataIn: [Float]) {
		// let scalingFactor = Float(self.height)
		// let scalingFactor = Float(1.0)
		let scalingFactor = Float(self.height / 4)
		
		let logarithmic = true
		
		// drop first half of data for better range
		var data = dataIn
		if dataIn.count > 0 {
			data = Array(data[...(data.count/8)])
		}
		
		heights = Array(repeating: 0, count: self.width)
		
		let linearStep = Double(data.count) / Double(self.width-1)
		var lastIndex = 0.0
		var currentIndex = linearStep
		if logarithmic {
			lastIndex = Double(data.count)
			currentIndex = Double(data.count / 2)
		}
		for i in 0..<self.width {
			let lastIndexInt = Int(lastIndex)
			let currentIndexInt = Int(currentIndex)
			var thisBucket: ArraySlice<Float>!
			if logarithmic {
				thisBucket = data[currentIndexInt..<lastIndexInt]
			} else {
				thisBucket = data[lastIndexInt..<currentIndexInt]
			}
			
			// self.clear()
			// self.write("\(thisBucket)", atPoint: (0, 0))
			
			var avg: Float = 0.0
			if thisBucket.count > 0 {
				avg = thisBucket.reduce(0, +) / Float(thisBucket.count)
			}
			// fputs("\(avg)\n", stderr)
			// self.write("\(avg)", atPoint: (1, 0))
			
			let h = Int(avg * scalingFactor)
			// let h = Int(Float(thisBucket.count) / Float(data.count) * Float(self.height * 2))
			
			lastIndex = currentIndex
			if logarithmic {
				heights[self.width-1 - i] = h
				currentIndex /= 2.0
			} else {
				heights[i] = h
				currentIndex += linearStep
			}
			
			// self.refresh()
		}
		
		self.draw()
	}
	
}
