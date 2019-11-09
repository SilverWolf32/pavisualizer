import Foundation
import CursesUI

class VisualizerView: InputResponsiveView {
	
	private var initializing = true
	private var initColumn = 0
	private var animationQueue: DispatchQueue? = nil
	private var audioMonitor: AudioMonitor? = nil
	
	override func draw(refresh doRefresh: Bool = true) {
		if animationQueue == nil {
			animationQueue = DispatchQueue.global(qos: .userInteractive)
			
			self.audioMonitor = AudioMonitor()
			self.audioMonitor?.startListening()
			
			animationQueue!.async { [unowned self] in
				while (true) {
					self.initColumn += 1
					if (self.initColumn >= self.width) {
						self.initializing = false
						return
					} else {
						self.write(".", atPoint: (self.height - 1, self.initColumn))
						self.refresh()
					}
					usleep(1_000_000 / UInt32(self.width)) // 1s total
				}
			}
			return
		}
		
		if (doRefresh) {
			self.refresh()
		}
	}
	
}
