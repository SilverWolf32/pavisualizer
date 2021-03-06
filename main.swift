import Foundation
import NCurses

var sink: String? = nil
if CommandLine.arguments.count > 1 {
	sink = CommandLine.arguments[1]
}

let audioMonitor = AudioMonitor()
audioMonitor.bufferSize = 1024*2
// audioMonitor.sampleRate = 44100 / 2
audioMonitor.refreshTime = UInt32(1_000_000/audioMonitor.sampleRate*audioMonitor.bufferSize/8)

NCurses.initDisplay()

let view = VisualizerView()

// view.smoothingWindow /= 2

view.instantActions["q"] = {
	NCurses.endDisplay()
	print("Exiting.")
	exit(64)
}
view.actionDescriptions["Q"] = { "Quit" }

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
