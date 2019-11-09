import Foundation
import CursesUI
import NCurses

/*
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

view.draw()
view.startAcceptingInput()

curs_set(0) // hide the cursor
*/

let audioMonitor = AudioMonitor()
audioMonitor.bufferSize = 32
audioMonitor.startListening()

// block
while true {
	usleep(10_000_000)
}
