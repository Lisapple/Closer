//
//  NoCountdownsInterfaceController.swift
//  Closer
//
//  Created by Max on 27/09/15.
//
//

import WatchKit
import WatchConnectivity

class NoCountdownsInterfaceController: WKInterfaceController {
	
	@IBOutlet private var instructionsLabel: WKInterfaceLabel!
	@IBOutlet private var newButton: WKInterfaceButton!
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		instructionsLabel.setText(LocalizedString("instruction.message"))
		newButton.setTitle(LocalizedString("new.button.title"))
		
		let context = WCSession.default().receivedApplicationContext
		let synchronised = (context["countdowns"] != nil) // Synchronised with iPhone
		instructionsLabel.setHidden(synchronised)
		newButton.setHidden(!synchronised)
		if (!synchronised) {
			addMenuItem(with: .add, title: LocalizedString("menu.action.new"), action: #selector(newAction(_:)))
		}
	}
	
	@IBAction func newAction(_ sender: AnyObject) {
		let countdown = Countdown(name: nil, identifier: nil, type: .countdown, style: nil)
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentController(withName: "EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
}
