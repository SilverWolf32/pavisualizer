import Foundation
import NCurses

/**

View

A class that functions like a tiled view, equivalent to (and based on) the Curses `window`.

*/
open class View {
	
	open class func initWindow(_ window: NCurses.Window!) {
		intrflush(window, false) // makes sure ncurses knows what's on the screen
		keypad(window, true) // allow getting e.g. arrow keys
		nodelay(window, true) // make wgetch() non-blocking
	}
	
	public private(set) var window: NCurses.Window! // ncurses window
	open var cursor: (Int, Int) {
		get {
			return (Int(getcury(window)), Int(getcurx(window)))
		}
		set(newCursor) {
			wmove(window, Int32(newCursor.0), Int32(newCursor.1))
		}
	}
	open var width: Int {
		return Int(getmaxx(window))
	}
	open var height: Int {
		return Int(getmaxy(window))
	}
	
	public convenience init() {
		self.init(height: NCurses.screenLines, y: 0)
	}
	public convenience init(height: Int, y: Int) {
		self.init(height: height, width: NCurses.screenCols, y: y, x: 0)
	}
	public init(height: Int, width: Int, y: Int, x: Int) {
		window = newwin(Int32(height), Int32(width), Int32(y), Int32(x))
		View.initWindow(window) // make sure it's set up
		
		cursor = (1, 1)
		// wrefresh(window)
	}
	deinit {
		delwin(window)
	}
	
	func drawBorder() {
		// draw top
		mvwaddstr(window, 0, 0, "┌")
		for _ in 1..<width-1 {
			waddstr(window, "─")
		}
		waddstr(window, "┐")
		// draw sides
		for x in [0, width-1] {
			for i in 1..<height-1 {
				mvwaddstr(window, Int32(i), Int32(x), "│")
			}
		}
		// draw bottom
		mvwaddstr(window, Int32(height-1), 0, "└")
		for _ in 1..<width-1 {
			waddstr(window, "─")
		}
		waddstr(window, "┘")
	}
	
	open func draw(refresh doRefresh: Bool = true) {
		let cursor = self.cursor
		
		werase(window)
		
		drawBorder()
		
		// write("\(Date())", atPoint: (0, 1))
		
		self.cursor = cursor
		
		if doRefresh {
			self.refresh()
		}
	}
	
	public func clear() {
		wclear(window)
	}
	public func refresh() {
		wrefresh(window)
	}
	
	public func move(to p: (Int, Int)) {
		wmove(window, Int32(p.0), Int32(p.1))
	}
	public func write(_ string: String) {
		waddstr(window, string)
	}
	public func write(_ string: String, atPoint p: (Int, Int)) {
		mvwaddstr(window, Int32(p.0), Int32(p.1), string)
	}
	
	public func focus() {
		// move the cursor to this view's cursor position
		wmove(window, Int32(cursor.0), Int32(cursor.1))
		draw()
	}
	
}
