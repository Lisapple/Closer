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
    }
	
	class func reload() {
		var names:[String] = []
		var contexts:[[String : AnyObject]] = []
		
		let userDefaults:NSUserDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
		let countdowns = userDefaults.arrayForKey("countdowns")! as [[String : AnyObject]]
		for countdown in countdowns {
			if (countdown["type"] as UInt == 1) {
				names.append("TimerItem")
			} else {
				names.append("CountdownItem")
			}
			var context:[String : AnyObject] = countdown as [String : AnyObject]
			context["style"] = ColorStyle.fromInt(countdown["style"] as Int).toString()
			contexts.append(context)
		}
		WKInterfaceController.reloadRootControllersWithNames(names, contexts: contexts)
	}

    override func willActivate() {
        super.willActivate()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}
