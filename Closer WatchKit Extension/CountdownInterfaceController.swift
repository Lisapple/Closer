//
//  CountdownInterfaceController.swift
//  TestWatch
//
//  Created by Max on 14/03/15.
//  Copyright (c) 2015 lis@cintosh. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class CountdownInterfaceController: WKInterfaceController {
	
	@IBOutlet var imageView: WKInterfaceImage!
	@IBOutlet var timerLabel: WKInterfaceTimer!
	@IBOutlet var descriptionLabel: WKInterfaceLabel!
	
	private weak var timer: NSTimer?
	private var countdown: Countdown? = nil
	private var hasChange: Bool = false
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		self.countdown = context as? Countdown
		self.setTitle(countdown?.name)
		
		updateUI()
		addMenuItemWithItemIcon(WKMenuItemIcon.Add, title: "New", action: #selector(newMenuAction))
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: #selector(deleteMenuAction))
		
		if (countdown?.identifier == NSUserDefaults().stringForKey("selectedIdentifier")) {
			self.becomeCurrentPage()
		}
	}
	
	func updateUI() {
		self.animateWithDuration(0.15) { () -> Void in // IDK if animation is working
			self.imageView.setImage(self.countdown!.progressionImageWithSize(CGSizeMake(74, 74), cornerRadius: 14))
		}
		if (countdown!.endDate != nil) {
			timerLabel.setDate(countdown!.endDate!)
			timerLabel.start()
			
			let formatter = NSDateFormatter()
			formatter.dateStyle = .MediumStyle
			descriptionLabel.setText("before \(formatter.stringFromDate(countdown!.endDate!))")
			descriptionLabel.setHidden(false)
		} else {
			timerLabel.setDate(NSDate())
			timerLabel.stop()
			descriptionLabel.setHidden(true)
		}
		
		if (countdown?.endDate != nil) {
			let interval = (countdown!.endDate!.timeIntervalSinceNow > 3 * 60) ? 60.0 : 1.0;
			timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: false)
			timer!.tolerance = interval / 2;
		}
	}
	
	@IBAction func newMenuAction() {
		let countdown = Countdown(name: nil, identifier: nil, type: .Countdown, style: nil)
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentControllerWithName("EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
	
	@IBAction func editMenuAction() {
		let options: EditOption = .ShowDeleteButton
		presentControllerWithName("EditInterface", context: [ "countdown" : countdown!, "options" : options.rawValue ])
		hasChange = true
	}
	
	@IBAction func deleteMenuAction() {
		WCSession.defaultSession().sendMessage(["action" : "delete", "identifier" : self.countdown!.identifier],
			replyHandler: { (replyInfo: [String : AnyObject]) -> Void in
				InterfaceController.reload()
			}, errorHandler: nil)
	}
	
	func didReceive(notification: NSNotification) {
		let identifier = notification.object as? String
		if (identifier == self.countdown?.identifier) {
			if (identifier != nil) {
				self.countdown = Countdown.countdownWith(identifier!)
			}
			updateUI()
		}
	}
	
	override func willActivate() {
		super.willActivate()
		updateUI()
		
		NSNotificationCenter.defaultCenter().removeObserver(self)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didReceive(_:)), name: "CountdownDidUpdateNotification", object: nil)
		
		if (hasChange) {
			let data = try? NSJSONSerialization.dataWithJSONObject(self.countdown!.toDictionary(), options: NSJSONWritingOptions(rawValue: 0))
			if (data != nil) {
				WCSession.defaultSession().sendMessage([ "action" : "update", "identifier" : self.countdown!.identifier, "data" : data! ],
					replyHandler: { (replyInfo: [String : AnyObject]) -> Void in }, errorHandler: nil)
			}
		}
		
		NSUserDefaults().setObject(self.countdown?.identifier, forKey: "selectedIdentifier")
		if (self.countdown != nil) {
			WCSession.defaultSession().sendMessage([ "action" : "update", "lastSelectedCountdownIdentifier" : self.countdown!.identifier ],
				replyHandler: { (replyInfo: [String : AnyObject]) -> Void in }, errorHandler: nil)
		}
	}
	
	override func didDeactivate() {
		super.didDeactivate()
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	deinit {
		self.timer?.invalidate()
	}
}
