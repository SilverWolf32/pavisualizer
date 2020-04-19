import Foundation
import NCurses

open class InputResponsiveView: View {
	
	public var instantActions: [Character: () -> ()] = [:]
	public var metaActions: [Character: () -> ()] = [:]
	public var specialActions: [Int32: () -> ()] = [:]
	public var metaSpecialActions: [Int32: () -> ()] = [:]
	public var actionDescriptions: [String: () -> String] = [:]
	
	private var inputQueue: OperationQueue? = nil
	
	open func startAcceptingInput() {
		inputQueue = OperationQueue()
		var op: BlockOperation!
		op = BlockOperation {
			while (!(op?.isCancelled ?? true)) {
				let _ = self.handleInput()
			}
		}
		inputQueue!.addOperation(op)
		// fputs("\(Date()) Accepting input.\n", stderr)
	}
	open func stopAcceptingInput() {
		inputQueue?.cancelAllOperations()
		inputQueue = nil
		// fputs("No longer accepting input.\n", stderr)
	}
	
	/**
	Handles input, performing actions as needed.
	Returns the input character, unless an action was performed.
	*/
	open func handleInput() -> Int32? {
		// fputs("Blocking for input.\n", stderr)
		wtimeout(window, -1) // blocking read
		let cAsInt = wgetch(window)
		let c = UInt32(cAsInt)
		guard let u = UnicodeScalar(c) else {
			endwin()
			fputs("*** Couldn't convert input to a unicode scalar! ***\n", stderr)
			exit(1)
		}
		let char = Character(u)
		
		if instantActions.keys.contains(char) {
			instantActions[char]!()
			return nil
		}
		if specialActions.keys.contains(cAsInt) {
			specialActions[cAsInt]!()
			return nil
		}
		
		if cAsInt == 27 { // ESC
			let newCharInt = wgetch(window)
			let nc = UInt32(newCharInt)
			guard let nu = UnicodeScalar(nc) else {
				endwin()
				fputs("*** Couldn't convert input to a unicode scalar! ***\n", stderr)
				exit(1)
			}
			let newChar = Character(nu)
			// meta actions go here
			
			if metaActions.keys.contains(newChar) {
				metaActions[newChar]!()
			}
			if metaSpecialActions.keys.contains(newCharInt) {
				metaSpecialActions[newCharInt]!()
			}
			
			return nil
		}
		
		return cAsInt
	}
	
}
