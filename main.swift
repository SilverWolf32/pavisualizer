import Foundation
import NCurses

var sink: String? = nil
if CommandLine.arguments.count > 1 {
	sink = CommandLine.arguments[1]
}

let audioMonitor = AudioMonitor()
audioMonitor.bufferSize = 1024*2
// audioMonitor.sampleRate = 44100 / 2
// audioMonitor.refreshTime = 0

NCurses.initDisplay()

let view = VisualizerView()
view.instantActions[" "] = { [unowned view] in
	// view.logarithmic = !view.logarithmic
	view.waveform = !view.waveform
	view.draw()
}
view.instantActions["w"] = { [unowned view] in
	view.waveformSolid = !view.waveformSolid
	view.draw()
}
view.instantActions["s"] = { [unowned view] in
	view.slowmode = !view.slowmode
}
view.instantActions["a"] = { [unowned view] in
	view.smoothSpectrum = !view.smoothSpectrum
}
view.instantActions["h"] = { [unowned view] in
	view.highPassWaveform = !view.highPassWaveform
}
view.instantActions["l"] = { [unowned view] in
	view.logarithmic = !view.logarithmic
}
view.instantActions["q"] = {
	NCurses.endDisplay()
	print("Exiting.")
	exit(64)
}

view.audioMonitor = audioMonitor

view.draw()
view.startAcceptingInput()

curs_set(0) // hide the cursor

audioMonitor.registerObserver(view)

audioMonitor.startListening(sink: sink)

// block
while true {
	usleep(10_000_000)
}
