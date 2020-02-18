import Foundation
import NCurses

/**

NCurses

A utility class that handles NCurses global operations, like setting up the initial screen.

*/

public class NCurses {
	
	// public typealias Window = OpaquePointer // ncurses window
	public typealias Window = UnsafeMutablePointer<WINDOW> // ncurses window
	
	public class var screenLines: Int {
		return Int(LINES)
	}
	public class var screenCols: Int {
		return Int(COLS)
	}
	
	public class func initDisplay() {
		setlocale(LC_ALL, "")
		
		initscr()
		cbreak()
		noecho()
		nonl() // allows detecting Return key
		
		View.initWindow(stdscr)
	}
	
	public class func endDisplay() {
		endwin()
	}
	
}
