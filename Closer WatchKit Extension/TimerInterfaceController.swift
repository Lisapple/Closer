//
//  PageInterfaceController.swift
//  TestWatch
//
//  Created by Max on 14/03/15.
//  Copyright (c) 2015 lis@cintosh. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class TimerInterfaceController: WKInterfaceController {
	
	@IBOutlet var imageView: WKInterfaceImage!
	@IBOutlet var timerLabel: WKInterfaceTimer!
	@IBOutlet var descriptionLabel: WKInterfaceLabel!
	@IBOutlet weak var toogleButton: WKInterfaceButton!
	
	private var remaining: NSTimeInterval = 0.0
	private var duration: NSTimeInterval = 0.0
	private var timer: NSTimer?
	private var paused: Bool = false {
		didSet {
			toogleButton?.setTitle((paused) ? "Resume" : "Pause")
			self.updateUI()
		}
	}
	
	private var countdown: Countdown? = nil
	private var hasChange: Bool = false
	
	override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
		self.countdown = context! as? Countdown
		
		self.setTitle(self.countdown?.name)
		if (countdown?.currentDuration != nil) {
			duration = countdown!.currentDuration!
		}
		self.paused = (countdown?.endDate == nil)
		
		updateUI()
		
		addMenuItemWithItemIcon(WKMenuItemIcon.Add, title: "New", action: #selector(newMenuAction))
		if (paused) {
			addMenuItemWithImageNamed("resume-button", title: "Resume", action: #selector(resumeMenuAction)) }
		else {
			addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: #selector(pauseMenuAction)) }
		
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: #selector(deleteMenuAction))
		
		if (countdown?.identifier == NSUserDefaults().stringForKey("selectedIdentifier")) {
			self.becomeCurrentPage()
		}
	}
	
	func updateUI() {
		updateProgressionImage()
		
		if (countdown!.endDate != nil) {
			timerLabel.setDate(countdown!.endDate!)
			timerLabel.start()
			
			if (countdown?.currentName != nil) {
				self.setTitle(countdown!.currentName!) }
			else {
				self.setTitle(countdown!.name) }
			
			let calendar = NSCalendar.currentCalendar()
			let components = NSDateComponents()
			if (countdown!.durations != nil && countdown!.durations!.count > 1 && countdown!.durationIndex != nil) {
				// "Next: [next duration]"
				let nextDurationIndex = (countdown!.durationIndex!+1) % countdown!.durations!.count
				components.second = Int(countdown!.durations![nextDurationIndex])
				let nextDate = calendar.dateFromComponents(components)
				descriptionLabel.setText("Next: \(NSDateFormatter.localizedStringFromDate(nextDate!, dateStyle: .NoStyle, timeStyle: .MediumStyle))")
			} else {
				// "of [total duration]"
				components.second = Int(duration)
				let date = calendar.dateFromComponents(components)
				descriptionLabel.setText("of \(NSDateFormatter.localizedStringFromDate(date!, dateStyle: .NoStyle, timeStyle: .MediumStyle))")
			}
			
			if (timer == nil) {
				let interval = (countdown!.endDate!.timeIntervalSinceNow > 30 * 60) ? 60.0 : 1.0
				timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(updateProgressionImage), userInfo: nil, repeats: true)
				timer!.tolerance = interval / 2
			}
		} else {
			timerLabel.stop()
			descriptionLabel.setHidden(true)
		}
    }
	
	func updateProgressionImage() {
		print("updateProgressionImage")
		self.imageView.setImage(self.countdown!.progressionImageWithSize(CGSizeMake(74, 74), cornerRadius: 74/2))
	}
	
	@IBAction func newMenuAction() {
		let countdown = Countdown(name: nil, identifier: nil, type: .Timer, style: nil)
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentControllerWithName("EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
	
	@IBAction func tooglePauseAction() {
		if (paused) {
			self.resumeMenuAction() }
		else {
			self.pauseMenuAction() }
	}
	
	@IBAction func pauseMenuAction() {
		WCSession.defaultSession().sendMessage(["action" : "pause", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : AnyObject]) -> Void in
				print(replyInfo["result"])
				if (self.countdown!.endDate != nil) {
					self.remaining = NSDate().timeIntervalSinceDate(self.countdown!.endDate!)
				}
				self.paused = true
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItemWithImageNamed("resume-button", title: "Resume", action: #selector(resumeMenuAction))
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: #selector(deleteMenuAction))
	}
	
	@IBAction func resumeMenuAction() {
		WCSession.defaultSession().sendMessage(["action" : "resume", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : AnyObject]) -> Void in
				print(replyInfo["result"])
				self.paused = false
				self.countdown!.endDate = NSDate().dateByAddingTimeInterval((self.remaining > 0.0) ? self.remaining : self.duration)
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: #selector(pauseMenuAction))
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: #selector(deleteMenuAction))
	}
	
	@IBAction func resetMenuAction() {
		WCSession.defaultSession().sendMessage(["action" : "reset", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : AnyObject]) -> Void in
				print(replyInfo["result"])
				self.countdown!.endDate = NSDate().dateByAddingTimeInterval(self.duration)
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: #selector(pauseMenuAction))
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: #selector(deleteMenuAction))
	}
	
	@IBAction func editMenuAction() {
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentControllerWithName("EditInterface", context: [ "countdown" : countdown!, "options" : options.rawValue ])
		hasChange = true
	}
	
	@IBAction func deleteMenuAction() {
		WCSession.defaultSession().sendMessage(["action" : "delete", "identifier" : countdown!.identifier],
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
		
		self.timer?.invalidate()
		self.timer = nil
    }
	
	deinit {
		self.paused = true
		self.timer?.invalidate()
		self.timer = nil
	}
}
