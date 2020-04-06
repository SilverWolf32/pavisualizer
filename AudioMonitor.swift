import Foundation
import PulseAudio
import KissFFT

class AudioMonitor {
	
	public var refreshTime: UInt32 = 10_000 // µs
	public var bufferSize = 1024
	public var sampleRate = 44100
	
	private var listeners: [AudioMonitorDelegate] = []
	
	private var pulseaudio: OpaquePointer? = nil
	private var readQueue: DispatchQueue? = nil
	
	private var currentRawData: [Int16] = []
	private var currentFFTData: [Float] = []
	private var lastBroadcastedData: [Int16] = []
	
	private var fftConfig: kiss_fft_cfg? = nil
	
	init(sink: String?) {
		var sampleSpec = pa_sample_spec(format: PA_SAMPLE_S16LE, rate: UInt32(sampleRate), channels: 1)
		var errorID: Int32 = 0
		pulseaudio = pa_simple_new(
			nil,
			"pavisualizer",
			PA_STREAM_RECORD,
			sink,
			"Audio visualization",
			&sampleSpec,
			nil,
			nil,
			&errorID
		)
		guard pulseaudio != nil else {
			fputs("PulseAudio connection failed: \(String(cString: pa_strerror(errorID)))", stderr)
			return
		}
	}
	
	func startListening() {
		initFFT()
		
		if self.readQueue == nil {
			self.readQueue = DispatchQueue.global(qos: .userInteractive)
		}
		self.readQueue!.async { [unowned self] in
			while true {
				var data: [Int16] = Array(repeating: 0, count: self.bufferSize/2)
				var errorID: Int32 = 0
				var result = pa_simple_flush(self.pulseaudio, &errorID)
				if result < 0 {
					fputs("PulseAudio read failed: \(String(cString: pa_strerror(errorID)))\n", stderr)
				}
				errorID = 0
				result = pa_simple_read(self.pulseaudio, &data, self.bufferSize, &errorID)
				if result < 0 {
					fputs("PulseAudio read failed: \(String(cString: pa_strerror(errorID)))\n", stderr)
				}
				// fputs("\(data)\n", stderr)
				
				self.currentRawData = data
				
				// perform FFT
				if data.max() ?? 0 == 0 {
					// nothing playing, no need to bother with the FFT
					let shouldBroadcast = true
					if self.lastBroadcastedData.max() ?? 0 == 0 {
						// already broadcasted 0, no need to do it again
						// shouldBroadcast = false
					}
					// during FFT it's cut to only left half, so do the same here
					self.currentFFTData = data[...(data.count/2)].map { Float($0) }
					if shouldBroadcast {
						self.broadcastData()
					}
				} else {
					// should we do an FFT?
					var shouldFFT = false
					for listener in self.listeners {
						if listener.shouldReceiveFFT() {
							shouldFFT = true
							break
						}
					}
					
					if shouldFFT {
						self.doFFT(data: data)
					} else {
						self.broadcastData()
					}
				}
				
				usleep(self.refreshTime)
			}
		}
	}
	
	func registerObserver(_ o: AudioMonitorDelegate) {
		listeners.append(o)
	}
	func unregisterObserver(_ o: AudioMonitorDelegate) {
		for i in 0..<listeners.count {
			if listeners[i] === o {
				listeners.remove(at: i)
				break
			}
		}
	}
	func broadcastData() {
		lastBroadcastedData = currentRawData
		for listener in listeners {
			listener.receiveWaveformData(currentRawData)
			if listener.shouldReceiveFFT() {
				listener.receiveSpectrumData(currentFFTData)
			}
		}
	}
	
	// FFT stuff //
	
	func initFFT() {
		fftConfig = kiss_fft_alloc(Int32(self.bufferSize/2), 0, nil, nil)
	}
	func deinitFFT() {
		// maaybe ARC can handle this?
		// free(fftConfig)
		fftConfig = nil
	}
	
	func doFFT(data dataIn: [Int16]) {
		// low-pass the data
		// see https://kiritchatterjee.wordpress.com/2014/11/10/a-simple-digital-low-pass-filter-in-c/
		// var rawData = dataIn
		/* for i in 1..<(rawData.count) {
			let weight = 0.5
			rawData[i] = Int16(weight * Double(rawData[i]) + (1-weight) * Double(rawData[i-1]))
		} */
		
		// print("\(rawData)\n")
		
		let kissFFTIn: [kiss_fft_cpx] = dataIn.map({ (n) in
			let normalized = Float(n) / Float(Int16.max)
			// print("\(normalized) ", terminator: "")
			return kiss_fft_cpx(r: normalized, i: 0)
		})
		
		var kissFFTOut = Array(repeating: kiss_fft_cpx(r: 0, i: 0), count: dataIn.count)
		kissFFTIn.withUnsafeBufferPointer { (fftIn) in
			kissFFTOut.withUnsafeMutableBufferPointer { (fftOut) in
				kiss_fft(fftConfig, fftIn.baseAddress, fftOut.baseAddress)
			}
		}
		
		var out = kissFFTOut.map({ (complex) in
			// return complex.r
			return sqrt(pow(complex.r, 2) + pow(complex.i, 2))
		})
		
		// scale the FFT data
		/* out = out.map({ (n) in
			return n / Float(out.count)
			// return n / sqrt(Float(out.count))
		}) */
		
		// apparently it's symmetrical, only need the first half
		out = Array(out[...(out.count/2)])
		
		// print("\(out)")
		
		currentFFTData = out
		
		broadcastData()
	}
	
	deinit {
		// NOTE: This is NOT necessarily called when the program exits!
		// The AudioMonitor has to be set to nil somewhere.
		pa_simple_free(pulseaudio)
		deinitFFT()
	}
	
}
