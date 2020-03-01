import Foundation

class VisualizerView: InputResponsiveView, AudioMonitorDelegate {
	
	public var audioMonitor: AudioMonitor? = nil
	public var logarithmic = false
	
	public var waveform = false
	
	public var barCharacter = "|"
	public var baseCharacter = "."
	public var baseCharacterW = "-" // for the waveform
	
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
						self.draw()
					}
					usleep(1_000_000 / UInt32(self.width)) // 1s total
				}
			}
			return
		}
		
		self.clear()
		
		for i in 0...self.initColumn {
			if waveform {
				self.write(self.baseCharacterW, atPoint: (self.height / 2, i))
			} else {
				self.write(self.baseCharacter, atPoint: (self.height - 1, i))
			}
		}
		
		if !initializing {
			// make sure the base dots are drawn all the way across
			self.initColumn = self.width
			
			for i in 0..<heights.count {
				let h = abs(heights[i])
				if waveform {
					for j in 0..<h {
						self.write(self.barCharacter, atPoint: (self.height / 2 - j, i))
						self.write(self.barCharacter, atPoint: (self.height / 2 + j, i))
					}
				} else {
					for j in 0..<h {
						self.write(self.barCharacter, atPoint: (self.height - 1 - j, i))
					}
				}
			}
		}
		
		if (doRefresh) {
			self.refresh()
		}
	}
	
	func receiveWaveformData(_ data: [UInt8]) {
		if waveform == false {
			return
		}
		
		let scalingFactor = 1.0/Double(self.height)
		
		heights = Array(repeating: 0, count: self.width)
		
		for i in 0..<self.width {
			// let dataIndex = Int(Double(i) / Double(self.width) * Double(data.count-1))
			let dataIndex = i*2
			let h = Int(Double(data[dataIndex]) * scalingFactor)
			heights[i] = h
		}
		
		self.draw()
	}
	
	func receiveSpectrumData(_ dataIn: [Float]) {
		if waveform == true {
			return
		}
		
		let scalingFactor = Float(self.height / 4)
		
		// limit to useful frequencies
		var data = dataIn
		let lowFreqBound = 100
		let highFreqBound = 4000
		let highestFreqInInput = (audioMonitor?.sampleRate ?? 44100)/2
		if dataIn.count > 0 {
			let lowIndex = Int(Double(lowFreqBound) / Double(highestFreqInInput) * Double(data.count))
			let highIndex = Int(Double(highFreqBound) / Double(highestFreqInInput) * Double(data.count))
			data = Array(data[lowIndex..<highIndex])
		}
		
		heights = Array(repeating: 0, count: self.width)
		
		let linearStep = Double(data.count) / Double(self.width)
		
		let nOctaves = log2(Double(highFreqBound) / Double(lowFreqBound))
		let logStep = (nOctaves - 1) / Double(self.width) + 1
		
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
			
			var max: Float = 0.0
			if thisBucket.count > 0 {
				max = thisBucket.max()!
			}
			
			let h = Int(max * scalingFactor)
			
			lastIndex = currentIndex
			if logarithmic {
				heights[self.width-1 - i] = h
				currentIndex /= logStep
			} else {
				heights[i] = h
				currentIndex += linearStep
			}
		}
		
		self.draw()
	}
	
}
