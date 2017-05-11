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
			toogleButton?.setTitle(
				LocalizedString((paused) ? "menu.action.resume" : "menu.action.pause"))
			self.updateUI()
		}
	}
	
	fileprivate var countdown: Countdown!
	fileprivate var hasChange: Bool = false
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		self.countdown = context! as? Countdown
		
		self.setTitle(self.countdown?.name)
		self.duration = countdown?.currentDuration ?? self.duration
		self.paused = (countdown?.endDate == nil)
		
		updateUI()
		
		addMenuItem(with: .add, title: LocalizedString("menu.action.new"), action: #selector(newMenuAction))
		if (paused) {
			addMenuItem(withImageNamed: "resume-button", title: LocalizedString("menu.action.resume"), action: #selector(resumeMenuAction)) }
		else {
			addMenuItem(with: .pause, title: LocalizedString("menu.action.pause"), action: #selector(pauseMenuAction)) }
		
		addMenuItem(withImageNamed: "reset-button", title: LocalizedString("menu.action.reset"), action: #selector(resetMenuAction))
		addMenuItem(with: .trash, title: LocalizedString("menu.action.delete"), action: #selector(deleteMenuAction))
		
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
				let text = DateFormatter.localizedString(from: nextDate!, dateStyle: .none, timeStyle: .medium)
				descriptionLabel.setText(LocalizedFormat("timer.label.next@", text))
			} else {
				// "of [total duration]"
				components.second = Int(duration)
				let date = calendar.date(from: components)
				let text = DateFormatter.localizedString(from: date!, dateStyle: .none, timeStyle: .medium)
				descriptionLabel.setText(LocalizedFormat("timer.label.of@", text))
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
		self.imageView.setImage(self.countdown!.progressionImage(size: CGSize(width: 74, height: 74), cornerRadius: 74/2))
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
		addMenuItem(with: #imageLiteral(resourceName: "resume-button"), title: LocalizedString("menu.action.resume"), action: #selector(resumeMenuAction))
		addMenuItem(with: #imageLiteral(resourceName: "reset-button"), title: LocalizedString("menu.action.reset"), action: #selector(resetMenuAction))
		addMenuItem(with: .trash, title:LocalizedString("menu.action.delete"), action: #selector(deleteMenuAction))
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
		addMenuItem(with: .pause, title: LocalizedString("menu.action.resume"), action: #selector(pauseMenuAction))
		addMenuItem(with: #imageLiteral(resourceName: "reset-button"), title: LocalizedString("menu.action.reset"), action: #selector(resetMenuAction))
		addMenuItem(with: .trash, title: LocalizedString("menu.action.delete"), action: #selector(deleteMenuAction))
	}
	
	@IBAction func resetMenuAction() {
		WCSession.default().sendMessage(["action" : "reset", "identifier" : countdown!.identifier],
			replyHandler: { (replyInfo: [String : Any]) -> Void in
				print(replyInfo["result"] ?? "")
				self.countdown!.endDate = Date().addingTimeInterval(self.duration)
				self.updateUI()
			}, errorHandler: nil)
		
		clearAllMenuItems()
		addMenuItem(with: .pause, title: LocalizedString("menu.action.pause"), action: #selector(pauseMenuAction))
		addMenuItem(with: #imageLiteral(resourceName: "reset-button"), title: LocalizedString("menu.action.reset"), action: #selector(resetMenuAction))
		addMenuItem(with: .trash, title: LocalizedString("menu.action.delete"), action: #selector(deleteMenuAction))
	}
	
	@IBAction func editMenuAction() {
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentController(withName: "EditInterface", context: [ "countdown" : countdown!, "options" : options.rawValue ])
		hasChange = true
	}
	
	@IBAction func deleteMenuAction() {
		WCSession.default().sendMessage(["action" : "delete", "identifier" : countdown!.identifier],
			replyHandler: { _ in
				InterfaceController.reload()
			}, errorHandler: nil)
	}
	
	func didReceive(_ notification: Notification) {
		if let identifier = notification.object as? String, identifier == self.countdown?.identifier {
			self.countdown = Countdown.with(identifier)
		}
		updateUI()
	}
	
	override func willActivate() {
		super.willActivate()
		updateUI()
		
		NotificationCenter.default.removeObserver(self)
		NotificationCenter.default.addObserver(self, selector: #selector(didReceive(_:)),
		                                       name: CountdownDidUpdateNotification, object: nil)
		
		if (hasChange) {
			if let data = try? JSONSerialization.data(withJSONObject: self.countdown!.toDictionary(), options: []) {
				let message: [String : Any] = [ "action" : "update", "identifier" : self.countdown!.identifier, "data" : data ]
				WCSession.default().sendMessage(message, replyHandler: { _ in }, errorHandler: nil)
			}
		}
		
		UserDefaults().set(self.countdown?.identifier, forKey: "selectedIdentifier")
		if let countdown = self.countdown {
			let message = [ "action" : "update", "lastSelectedCountdownIdentifier" : countdown.identifier ]
			WCSession.default().sendMessage(message, replyHandler: { _ in }, errorHandler: nil)
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
