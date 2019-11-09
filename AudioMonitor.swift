import PulseAudio

class AudioMonitor {
	
	private var pulseaudio: OpaquePointer? = nil
	
	init() {
		var sampleSpec = pa_sample_spec(format: PA_SAMPLE_S16LE, rate: 44100, channels: 1)
		var errorPointer: Int32 = 0
		pulseaudio = pa_simple_new(
			nil,
			"pavisualizer",
			PA_STREAM_RECORD,
			nil,
			"Audio visualization",
			&sampleSpec,
			nil,
			nil,
			&errorPointer
		)
		guard pulseaudio != nil else {
			print("PulseAudio connection failed: \(String(cString: pa_strerror(errorPointer)))")
			return
		}
	}
	
}
