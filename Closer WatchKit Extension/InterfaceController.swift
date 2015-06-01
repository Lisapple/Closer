//
//  InterfaceController.swift
//  Closer WatchKit Extension
//
//  Created by Max on 23/03/15.
//
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
		
		InterfaceController.reload()
		
		NotificationHelper.sharedInstance().startObservingNotificationName("Darwin_CountdownDidUpdateNotification");
		
		NotificationHelper.sharedInstance().startObservingNotificationName("Darwin_CountdownDidSynchronizeNotification");
		NSNotificationCenter.defaultCenter().addObserverForName("Darwin_CountdownDidSynchronizeNotification", object: nil, queue: nil) {
			(notification) -> Void in InterfaceController.reload()
		}
    }
	
	static var pageCount:Int = 0;
	class func reload() {
		var names:[String] = []
		var contexts:[[String : AnyObject]] = []
		
		let userDefaults:NSUserDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
		let representation = userDefaults.dictionaryRepresentation()
		if (userDefaults.arrayForKey("countdowns") != nil) {
			let countdowns = userDefaults.arrayForKey("countdowns") as! [[String : AnyObject]]
			for countdown in countdowns {
				if (countdown["type"] as! UInt == 1 /* Timer */) {
					names.append("TimerItem")
				} else {
					names.append("CountdownItem")
				}
				var context:[String : AnyObject] = countdown as [String : AnyObject]
				context["style"] = countdown["style"] as! Int
				contexts.append(context)
			}
		}
		if (contexts.count == 0) { // No countdowns, show error message
			WKInterfaceController.reloadRootControllersWithNames(["NoCountdowns"], contexts: [])
		} else if (pageCount != contexts.count) {
			WKInterfaceController.reloadRootControllersWithNames(names, contexts: contexts)
			pageCount = contexts.count;
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
