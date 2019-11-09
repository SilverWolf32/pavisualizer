import Foundation
import CursesUI
import NCurses

NCurses.initDisplay()

let view = InputResponsiveView()
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

// block
while true {
	usleep(10_000_000)
}
