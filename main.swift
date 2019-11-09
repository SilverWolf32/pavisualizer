import Foundation
import CursesUI

let view = InputResponsiveView()
view.instantActions[" "] = { [unowned view] in
	view.write("\u{7}", atPoint: (0, 0))
}
view.instantActions["q"] = {
	NCurses.endDisplay()
	print("Exiting.")
	exit(0)
}

print("Setting up display [\(NCurses.screenCols)x\(NCurses.screenLines)]...");
usleep(1_000_000);
NCurses.initDisplay()
usleep(1_000_000);
view.draw()
