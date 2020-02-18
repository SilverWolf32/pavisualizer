import Foundation
import PulseAudio
import KissFFT

class AudioMonitor {
	
	public var refreshTime: UInt32 = 10_000 // µs
	public var bufferSize = 1024
	
	private var listeners: [AudioMonitorDelegate] = []
	
	private var pulseaudio: OpaquePointer? = nil
	private var readQueue: DispatchQueue? = nil
	
	private var currentFFTData: [Float] = []
	
	private var fftConfig: kiss_fft_cfg? = nil
	
	init(sink: String?) {
		var sampleSpec = pa_sample_spec(format: PA_SAMPLE_S16LE, rate: 44100, channels: 1)
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
		
		initFFT()
	}
	
	func startListening() {
		if self.readQueue == nil {
			self.readQueue = DispatchQueue.global(qos: .userInteractive)
		}
		self.readQueue!.async {
			while true {
				var data: [UInt8] = Array(repeating: 0, count: self.bufferSize)
				var errorID: Int32 = 0
				var result = pa_simple_flush(self.pulseaudio, &errorID)
				if result < 0 {
					fputs("PulseAudio read failed: \(String(cString: pa_strerror(errorID)))", stderr)
				}
				errorID = 0
				result = pa_simple_read(self.pulseaudio, &data, self.bufferSize, &errorID)
				if result < 0 {
					fputs("PulseAudio read failed: \(String(cString: pa_strerror(errorID)))", stderr)
				}
				// fputs("\(data)\n", stderr)
				
				// perform FFT
				self.doFFT(data: data)
				
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
		for listener in listeners {
			listener.receiveSpectrumData(currentFFTData);
		}
	}
	
	// FFT stuff //
	
	func initFFT() {
		fftConfig = kiss_fft_alloc(Int32(self.bufferSize), 0, nil, nil)
	}
	func deinitFFT() {
		// maaybe ARC can handle this?
		// free(fftConfig)
		fftConfig = nil
	}
	
	func doFFT(data dataIn: [UInt8]) {
		// low-pass the data
		// see https://kiritchatterjee.wordpress.com/2014/11/10/a-simple-digital-low-pass-filter-in-c/
		var rawData = dataIn
		for i in 1..<(rawData.count) {
			let weight = 0.5
			rawData[i] = UInt8(weight * Double(rawData[i]) + (1-weight) * Double(rawData[i-1]))
		}
		
		// print("\(rawData)\n")
		
		let kissFFTIn: [kiss_fft_cpx] = rawData.map({ (n) in
			return kiss_fft_cpx(r: Float(n), i: 0)
		})
		
		var kissFFTOut = Array(repeating: kiss_fft_cpx(r: 0, i: 0), count: rawData.count)
		kissFFTIn.withUnsafeBufferPointer { (fftIn) in
			kissFFTOut.withUnsafeMutableBufferPointer { (fftOut) in
				kiss_fft(fftConfig, fftIn.baseAddress, fftOut.baseAddress)
			}
		}
		
		var out = kissFFTOut.map({ (complex) in
			return complex.r
			// return sqrt(pow(complex.r, 2) + pow(complex.i, 2))
		})
		
		// scale the FFT data
		out = out.map({ (n) in
			return n / Float(out.count)
			// return n / sqrt(Float(out.count))
		})
		
		// apparently it's symmetrical, only need the last half
		out = Array(out[(out.count/2)...])
		
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
