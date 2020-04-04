import Foundation

class VisualizerView: InputResponsiveView, AudioMonitorDelegate {
	
	public var audioMonitor: AudioMonitor? = nil
	public var logarithmic = false
	
	public var waveform = false
	public var slowmode = true
	public var smoothSpectrum = false
	public var highPassWaveform = false
	
	public var barCharacter = "|"
	public var baseCharacter = "."
	public var baseCharacterW = "-" // for the waveform
	
	public var maxWaveformHeight = 16
	
	private var initializing = true
	private var initColumn = 0
	private var animationQueue: DispatchQueue? = nil
	
	private var heights: [Int] = []
	
	private var historicalSpectrumData: [[Float]] = []
	private var historicalWaveformData: [[Float]] = []
	private var smoothingWindow = [
		"spectrum": 64,
		"waveform": 2
	]
	private var spectrumLowPassFactor = 0.3
	
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
					usleep(500_000 / UInt32(self.width)) // 1s total
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
	
	func receiveWaveformData(_ dataIn: [UInt8]) {
		var data = dataIn.map { Float($0) }
		historicalWaveformData.append(data)
		if historicalWaveformData.count > smoothingWindow["waveform"]! {
			historicalWaveformData.removeFirst()
		}
		if slowmode {
			data = calculateMovingAverage(historicalWaveformData)
			// data = data.map { $0 * Float(historicalWaveformData.count)/2.0 }
			// data = data.map { $0 * 2 }
		}
		
		if waveform == false {
			return
		}
		
		// high pass the data
		// otherwise at only low frequencies it can show large blocks of full and empty
		// see https://en.wikipedia.org/wiki/High-pass_filter#Algorithmic_implementation
		if highPassWaveform {
			var newData: [Float] = Array(repeating: 0, count: data.count)
			let α = Float(0.95)
			for i in 1..<data.count {
				newData[i] = α * (newData[i-1] + data[i] - data[i-1])
			}
			newData = newData.map { $0 / (0.8*α) }
			newData[0] = data[0]
			data = newData
		}
		
		let scalingFactor = 1.0 / 512 * Double(min(self.height, self.maxWaveformHeight))
		
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
		
		historicalSpectrumData.append(data)
		if historicalSpectrumData.count > smoothingWindow["spectrum"]! {
			historicalSpectrumData.removeFirst()
		}
		if slowmode {
			data = calculateMovingAverage(historicalSpectrumData)
			data = data.map { $0 * Float(historicalSpectrumData.count)/4.0 }
		}
		
		if smoothSpectrum {
			// low-pass the data
			// see https://kiritchatterjee.wordpress.com/2014/11/10/a-simple-digital-low-pass-filter-in-c/
			let weight = spectrumLowPassFactor
			for i in 1..<(data.count) {
				data[i] = Float(weight * Double(data[i]) + (1-weight) * Double(data[i-1]))
			}
			data = data.map { $0 * Float(log2(1/spectrumLowPassFactor)) }
		}
		
		if data.count < self.width {
			// make more data!
			// interpolate between existing values
			var newData: [Float] = []
			newData.reserveCapacity(data.count * 2)
			for i in 0..<data.count-1 {
				newData.append(data[i])
				newData.append((data[i] + data[i+1])/2)
			}
			data = newData
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
	
	func shouldReceiveFFT() -> Bool {
		return !self.waveform // don't receive FFTs when in waveform mode
	}
	
	private func calculateMovingAverage(_ historicalData: [[Float]]) -> [Float] {
		var data: [Float] = Array(repeating: 0, count: historicalData[0].count)
		// calculate weighted average of the historical spectrum data
		// see https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
		// see https://www.fidelity.com/learning-center/trading-investing/technical-analysis/technical-indicator-guide/wma
		for i in 0..<data.count {
			data[i] = 0
			let n = historicalData.count
			for j in 1...n {
				data[i] += Float(j) * historicalData[j-1][i]
			}
			data[i] /= Float((n*(n+1))/2)
		}
		return data
	}
	
}
