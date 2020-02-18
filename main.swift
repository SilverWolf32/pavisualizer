import Foundation
import CursesUI
import NCurses

var sink: String? = nil
if CommandLine.arguments.count > 1 {
	sink = CommandLine.arguments[1]
}

let audioMonitor = AudioMonitor(sink: sink)
audioMonitor.bufferSize = 1024*2
audioMonitor.refreshTime = 0

// /*
NCurses.initDisplay()

let view = VisualizerView()
view.instantActions[" "] = {
	beep()
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
// */

audioMonitor.startListening()

// block
while true {
	usleep(10_000_000)
}
