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
		print(message)
		if (message["update"] is Bool && (message["update"]! as! Bool) == true) {
			InterfaceController.reload()
		}
		replyHandler(["result" : "OK"])
	}
}

class InterfaceController: WKInterfaceController, WCSessionDelegate {
	
	private static var sessionDelegate: SessionDelegate?
	private static var once: dispatch_once_t = 0
	
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
	
	class func reload() {
		var names = [String]()
		var contexts = [Countdown]()
		for countdown in Countdown.allCountdowns() {
			names.append((countdown.type == .Timer) ? "TimerItem" : "CountdownItem")
			contexts.append(countdown)
		}
		if (contexts.count == 0) { // No countdowns, show error message
			WKInterfaceController.reloadRootControllersWithNames(["NoCountdowns"], contexts: [])
		} else {
			WKInterfaceController.reloadRootControllersWithNames(names, contexts: contexts)
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
