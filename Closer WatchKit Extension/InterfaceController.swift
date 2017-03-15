//
//  InterfaceController.swift
//  Closer WatchKit Extension
//
//  Created by Max on 23/03/15.
//
//

import WatchKit
import WatchConnectivity

class SessionDelegate: NSObject, WCSessionDelegate {
	
	@available(watchOSApplicationExtension 2.2, *)
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		if (message["update"] is Bool && (message["update"]! as! Bool) == true) {
			InterfaceController.reload()
			
			let identifier = message["identifier"] as? String
			var identifiers: [String]? = (identifier != nil) ? [identifier!] : nil
			if (identifiers == nil) {
				identifiers = Countdown.allCountdowns().map({ (countdown: Countdown) -> String in
					return countdown.identifier })
			}
			if (identifiers != nil) {
				for identifier in identifiers! {
					NotificationCenter.default.post(name: Notification.Name(rawValue: "CountdownDidUpdateNotification"), object: identifier)
				}
			}
		}
		replyHandler(["result" : "OK"])
	}
}

class InterfaceController: WKInterfaceController {
	
	private static var __once: () = { () -> Void in
			let session = WCSession.default()
			InterfaceController.sessionDelegate = SessionDelegate()
			session.delegate = InterfaceController.sessionDelegate
			session.activate()
		}()
	
	fileprivate static var sessionDelegate: SessionDelegate?
	fileprivate static var once: Int = 0
	fileprivate static var countdowns = [Countdown]()
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		_ = InterfaceController.__once
		
		InterfaceController.reload()
	}
	
	fileprivate class func hasChange() -> Bool {
		
		let newCountdowns = Countdown.allCountdowns()
		var index = 0
		if (newCountdowns.count == self.countdowns.count) {
			for countdown in newCountdowns {
				if (countdown.identifier == self.countdowns[index].identifier &&
					countdown.type == self.countdowns[index].type &&
					countdown.name == self.countdowns[index].name) {
				} else {
					break
				}
				index += 1
			}
		}
		return (index != newCountdowns.count)
	}
	
	class func reload() {
		if (self.hasChange()) {
			self.countdowns = Countdown.allCountdowns()
			
			var names = [String]()
			var contexts = [Countdown]()
			for countdown in self.countdowns {
				names.append((countdown.type == .timer) ? "TimerItem" : "CountdownItem")
				contexts.append(countdown)
			}
			if (contexts.count == 0) { // No countdowns, show error message
				WKInterfaceController.reloadRootControllers(withNames: ["NoCountdowns"], contexts: [])
			} else {
				WKInterfaceController.reloadRootControllers(withNames: names, contexts: contexts)
			}
		}
	}
	
	override func willActivate() {
		super.willActivate()
		InterfaceController.reload()
	}
	
	override func didDeactivate() {
		super.didDeactivate()
	}
}
