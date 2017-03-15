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
	
	fileprivate var remaining: TimeInterval = 0.0
	fileprivate var duration: TimeInterval = 0.0
	fileprivate var timer: Timer?
	fileprivate var paused: Bool = false {
		didSet {
			toogleButton?.setTitle((paused) ? "Resume" : "Pause")
			self.updateUI()
		}
	}
	
	fileprivate var countdown: Countdown? = nil
	fileprivate var hasChange: Bool = false
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		self.countdown = context! as? Countdown
		
		self.setTitle(self.countdown?.name)
		self.duration = countdown?.currentDuration ?? self.duration
		self.paused = (countdown?.endDate == nil)
		
		updateUI()
		
		addMenuItem(with: WKMenuItemIcon.add, title: "New", action: #selector(newMenuAction))
		if (paused) {
			addMenuItem(withImageNamed: "resume-button", title: "Resume", action: #selector(resumeMenuAction)) }
		else {
			addMenuItem(with: WKMenuItemIcon.pause, title: "Pause", action: #selector(pauseMenuAction)) }
		
		addMenuItem(withImageNamed: "reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: #selector(deleteMenuAction))
		
		if (countdown?.identifier == UserDefaults().string(forKey: "selectedIdentifier")) {
			self.becomeCurrentPage()
		}
	}
	
	func updateUI() {
		updateProgressionImage()
		
		if (countdown!.endDate != nil) {
			timerLabel.setDate(countdown!.endDate! as Date)
			timerLabel.start()
			
			if (countdown?.currentName != nil) {
				self.setTitle(countdown!.currentName!) }
			else {
				self.setTitle(countdown!.name) }
			
			let calendar = Calendar.current
			var components = DateComponents()
			if (countdown!.durations != nil && countdown!.durations!.count > 1 && countdown!.durationIndex != nil) {
				// "Next: [next duration]"
				let nextDurationIndex = (countdown!.durationIndex!+1) % countdown!.durations!.count
				components.second = Int(countdown!.durations![nextDurationIndex])
				let nextDate = calendar.date(from: components)
				descriptionLabel.setText("Next: \(DateFormatter.localizedString(from: nextDate!, dateStyle: .none, timeStyle: .medium))")
			} else {
				// "of [total duration]"
				components.second = Int(duration)
				let date = calendar.date(from: components)
				descriptionLabel.setText("of \(DateFormatter.localizedString(from: date!, dateStyle: .none, timeStyle: .medium))")
			}
			
			if (timer == nil) {
				let interval = (countdown!.endDate!.timeIntervalSinceNow > 30 * 60) ? 60.0 : 1.0
				timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateProgressionImage), userInfo: nil, repeats: true)
				timer!.tolerance = interval / 2
			}
		} else {
			timerLabel.stop()
			descriptionLabel.setHidden(true)
		}
	}
	
	func updateProgressionImage() {
		self.imageView.setImage(self.countdown!.progressionImageWithSize(CGSize(width: 74, height: 74), cornerRadius: 74/2))
	}
	
	@IBAction func newMenuAction() {
		let countdown = Countdown(name: nil, identifier: nil, type: .timer, style: nil)
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentController(withName: "EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
	
	@IBAction func tooglePauseAction() {
		if (paused) {
			self.resumeMenuAction() }
		else {
			self.pauseMenuAction() }
	}
	
	@IBAction func pauseMenuAction() {
		WCSession.default().sendMessage(["action" : "pause", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : Any]) -> Void in
				print(replyInfo["result"] ?? "")
				if (self.countdown!.endDate != nil) {
					self.remaining = Date().timeIntervalSince(self.countdown!.endDate!)
				}
				self.paused = true
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItem(withImageNamed: "resume-button", title: "Resume", action: #selector(resumeMenuAction))
		addMenuItem(withImageNamed: "reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: #selector(deleteMenuAction))
	}
	
	@IBAction func resumeMenuAction() {
		WCSession.default().sendMessage(["action" : "resume", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : Any]) -> Void in
				print(replyInfo["result"] ?? "")
				self.paused = false
				self.countdown!.endDate = Date().addingTimeInterval((self.remaining > 0.0) ? self.remaining : self.duration)
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItem(with: WKMenuItemIcon.pause, title: "Pause", action: #selector(pauseMenuAction))
		addMenuItem(withImageNamed: "reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: #selector(deleteMenuAction))
	}
	
	@IBAction func resetMenuAction() {
		WCSession.default().sendMessage(["action" : "reset", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : Any]) -> Void in
				print(replyInfo["result"] ?? "")
				self.countdown!.endDate = Date().addingTimeInterval(self.duration)
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItem(with: WKMenuItemIcon.pause, title: "Pause", action: #selector(pauseMenuAction))
		addMenuItem(withImageNamed: "reset-button", title: "Reset", action: #selector(resetMenuAction))
		addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: #selector(deleteMenuAction))
	}
	
	@IBAction func editMenuAction() {
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentController(withName: "EditInterface", context: [ "countdown" : countdown!, "options" : options.rawValue ])
		hasChange = true
	}
	
	@IBAction func deleteMenuAction() {
		WCSession.default().sendMessage(["action" : "delete", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : Any]) -> Void in
				InterfaceController.reload()
			}, errorHandler: nil)
	}
	
	func didReceive(_ notification: Notification) {
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
		
		NotificationCenter.default.removeObserver(self)
		NotificationCenter.default.addObserver(self, selector: #selector(didReceive(_:)),
		                                       name: NSNotification.Name(rawValue: "CountdownDidUpdateNotification"), object: nil)
		
		if (hasChange) {
			let data = try? JSONSerialization.data(withJSONObject: self.countdown!.toDictionary(), options: [])
			if (data != nil) {
				WCSession.default().sendMessage([ "action" : "update", "identifier" : self.countdown!.identifier, "data" : data! ],
				                                replyHandler: { (replyInfo: [String : Any]) -> Void in }, errorHandler: nil)
			}
		}
		
		UserDefaults().set(self.countdown?.identifier, forKey: "selectedIdentifier")
		if (self.countdown != nil) {
			WCSession.default().sendMessage([ "action" : "update", "lastSelectedCountdownIdentifier" : self.countdown!.identifier ],
				replyHandler: { (replyInfo: [String : Any]) -> Void in }, errorHandler: nil)
		}
	}
	
	override func didDeactivate() {
		super.didDeactivate()
		NotificationCenter.default.removeObserver(self)
		
		self.timer?.invalidate()
		self.timer = nil
	}
	
	deinit {
		self.paused = true
		self.timer?.invalidate()
		self.timer = nil
	}
}
