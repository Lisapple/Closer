//
//  NoCountdownsInterfaceController.swift
//  Closer
//
//  Created by Max on 27/09/15.
//
//

import WatchKit

class NoCountdownsInterfaceController: WKInterfaceController {
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		addMenuItem(with: WKMenuItemIcon.add, title: "New", action: #selector(newAction(_:)))
	}
	
	@IBAction func newAction(_ sender: AnyObject) {
		let countdown = Countdown(name: nil, identifier: nil, type: .countdown, style: nil)
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentController(withName: "EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
}
