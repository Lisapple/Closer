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
	
	func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
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
					NSNotificationCenter.defaultCenter().postNotificationName("CountdownDidUpdateNotification", object: identifier)
				}
			}
		}
		replyHandler(["result" : "OK"])
	}
}

class InterfaceController: WKInterfaceController, WCSessionDelegate {
	
	private static var sessionDelegate: SessionDelegate?
	private static var once: dispatch_once_t = 0
	private static var countdowns = [Countdown]()
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
		
		dispatch_once(&InterfaceController.once) { () -> Void in
			let session = WCSession.defaultSession()
			InterfaceController.sessionDelegate = SessionDelegate()
			session.delegate = InterfaceController.sessionDelegate
			session.activateSession()
		}
		
		InterfaceController.reload()
    }
	
	private class func hasChange() -> Bool {
		
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
				++index
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
				names.append((countdown.type == .Timer) ? "TimerItem" : "CountdownItem")
				contexts.append(countdown)
			}
			if (contexts.count == 0) { // No countdowns, show error message
				WKInterfaceController.reloadRootControllersWithNames(["NoCountdowns"], contexts: [])
			} else {
				WKInterfaceController.reloadRootControllersWithNames(names, contexts: contexts)
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
