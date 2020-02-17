import Foundation
import PulseAudio
import KissFFT

class AudioMonitor {
	
	public var refreshTime: UInt32 = 10_000 // µs
	public var bufferSize = 1024
	
	private var pulseaudio: OpaquePointer? = nil
	private var readQueue: DispatchQueue? = nil
	
	private var fftConfig: kiss_fft_cfg? = nil
	
	init() {
		var sampleSpec = pa_sample_spec(format: PA_SAMPLE_S16LE, rate: 44100, channels: 1)
		var errorID: Int32 = 0
		pulseaudio = pa_simple_new(
			nil,
			"pavisualizer",
			PA_STREAM_RECORD,
			nil,
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
				let result = pa_simple_read(self.pulseaudio, &data, self.bufferSize, &errorID)
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
	
	// FFT stuff //
	
	func initFFT() {
	}
	func deinitFFT() {
	}
	
	func doFFT(data rawData: [UInt8]) {
		fftConfig = kiss_fft_alloc(Int32(rawData.count), 0, nil, nil)
		
		let kissFFTIn: [kiss_fft_cpx] = rawData.map({ (n) in
			return kiss_fft_cpx(r: Float(n), i: 0)
		})
		
		var kissFFTOut = Array(repeating: kiss_fft_cpx(r: 0, i: 0), count: rawData.count)
		kissFFTIn.withUnsafeBufferPointer { (fftIn) in
			kissFFTOut.withUnsafeMutableBufferPointer { (fftOut) in
				kiss_fft(fftConfig, fftIn.baseAddress, fftOut.baseAddress)
			}
		}
		
		let out = kissFFTOut.map({ (complex) in
			return complex.r // real component
		})
		
		print("\(out)")
		
		// maaybe ARC can handle this?
		// free(fftConfig)
		fftConfig = nil
	}
	
	deinit {
		// NOTE: This is NOT necessarily called when the program exits!
		// The AudioMonitor has to be set to nil somewhere.
		pa_simple_free(pulseaudio)
		deinitFFT()
	}
	
}
