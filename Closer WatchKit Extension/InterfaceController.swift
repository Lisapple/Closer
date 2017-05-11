//
//  InterfaceController.swift
//  Closer WatchKit Extension
//
//  Created by Max on 23/03/15.
//
//

import WatchKit
import WatchConnectivity

let CountdownDidUpdateNotification = Notification.Name(rawValue: "CountdownDidUpdateNotification")

class SessionDelegate: NSObject, WCSessionDelegate {
	
	@available(watchOSApplicationExtension 2.2, *)
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		if let updated = message["update"] as? Bool, updated {
			InterfaceController.reload()
			
			let identifier = message["identifier"] as? String
			let identifiers = (identifier != nil) ? [identifier!] : Countdown.all.map { $0.identifier }
			identifiers.forEach {
				NotificationCenter.default.post(name: CountdownDidUpdateNotification, object: $0)
			}
		}
		replyHandler(["result" : "OK"])
	}
}

class InterfaceController: WKInterfaceController {
	
	private static let sessionDelegate = SessionDelegate()
	private static var countdowns = [Countdown]()
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		let session = WCSession.default()
		session.delegate = InterfaceController.sessionDelegate
		session.activate()
		
		InterfaceController.reload()
	}
	
	/// Returns true if countdowns list need refreshing
	private static var needsReload: Bool {
		let newCountdowns = Countdown.all
		var index = 0
		if (newCountdowns.count == self.countdowns.count) {
			for countdown in newCountdowns {
				let matching = (countdown.identifier == self.countdowns[index].identifier &&
					countdown.type == self.countdowns[index].type &&
					countdown.name == self.countdowns[index].name)
				if (!matching) {
					return true
				}
				index += 1
			}
			return false
		}
		return true
	}
	
	class func reload() {
		if (self.needsReload || Countdown.all.count == 0) {
			self.countdowns = Countdown.all
			let names = self.countdowns.map { ($0.type == .timer) ? "TimerItem" : "CountdownItem" }
			if (names.count > 0) {
				WKInterfaceController.reloadRootControllers(withNames: names, contexts: self.countdowns)
			} else { // No countdowns, show error message
				WKInterfaceController.reloadRootControllers(withNames: ["NoCountdowns"], contexts: [])
			}
		}
	}
	
	override func willActivate() {
		super.willActivate()
		InterfaceController.reload()
	}
}
