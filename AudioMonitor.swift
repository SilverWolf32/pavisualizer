import Foundation
import PulseAudio

class AudioMonitor {
	
	public var refreshTime: UInt32 = 10_000 // µs
	public var bufferSize = 1024
	
	private var pulseaudio: OpaquePointer? = nil
	private var timingQueue: DispatchQueue? = nil
	
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
	}
	
	func startListening() {
		if self.timingQueue == nil {
			self.timingQueue = DispatchQueue.global(qos: .userInteractive)
		}
		self.timingQueue!.async {
			while true {
				var data: [UInt8] = Array(repeating: 0, count: self.bufferSize)
				var errorID: Int32 = 0
				let result = pa_simple_read(self.pulseaudio, &data, self.bufferSize, &errorID)
				if result < 0 {
					fputs("PulseAudio read failed: \(String(cString: pa_strerror(errorID)))", stderr)
				}
				fputs("\(data)\n", stderr)
				usleep(self.refreshTime)
			}
		}
	}
	
	deinit {
		pa_simple_free(pulseaudio)
	}
	
}
