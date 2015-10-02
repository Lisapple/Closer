//
//  NoCountdownsInterfaceController.swift
//  Closer
//
//  Created by Max on 27/09/15.
//
//

import WatchKit

class NoCountdownsInterfaceController: WKInterfaceController {
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		
		addMenuItemWithItemIcon(WKMenuItemIcon.Add, title: "New", action: "newAction:")
	}
	
	@IBAction func newAction(sender: AnyObject) {
		let countdown = Countdown(name: nil, identifier: nil, type: .Countdown, style: nil)
		let options: EditOption = [ .ShowDoneButton, .ShowDeleteButton ]
		presentControllerWithName("EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
}
