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
	
	fileprivate weak var timer: Timer?
	fileprivate var countdown: Countdown? = nil
	fileprivate var hasChange: Bool = false
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		self.countdown = context as? Countdown
		self.setTitle(countdown?.name)
		
		updateUI()
		addMenuItem(with: WKMenuItemIcon.add, title: "New", action: #selector(newMenuAction))
		addMenuItem(with: WKMenuItemIcon.trash, title: "Delete", action: #selector(deleteMenuAction))
		
		if (countdown?.identifier == UserDefaults().string(forKey: "selectedIdentifier")) {
			self.becomeCurrentPage()
		}
	}
	
	func updateUI() {
		self.animate(withDuration: 0.15) { () -> Void in // IDK if animation is working
			self.imageView.setImage(self.countdown!.progressionImageWithSize(CGSize(width: 74, height: 74), cornerRadius: 14))
		}
		if (countdown!.endDate != nil) {
			timerLabel.setDate(countdown!.endDate! as Date)
			timerLabel.start()
			
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			descriptionLabel.setText("before \(formatter.string(from: countdown!.endDate! as Date))")
			descriptionLabel.setHidden(false)
		} else {
			timerLabel.setDate(Date())
			timerLabel.stop()
			descriptionLabel.setHidden(true)
		}
		
		if (countdown?.endDate != nil) {
			let interval = (countdown!.endDate!.timeIntervalSinceNow > 3 * 60) ? 60.0 : 1.0;
			timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateUI), userInfo: nil, repeats: false)
			timer!.tolerance = interval / 2;
		}
	}
	
	@IBAction func newMenuAction() {
		let countdown = Countdown(name: nil, identifier: nil, type: .countdown, style: nil)
		let options: EditOption = [ .ShowAsCreate, .ShowDeleteButton ]
		presentController(withName: "EditInterface", context: [ "countdown" : countdown, "options" : options.rawValue ])
	}
	
	@IBAction func editMenuAction() {
		let options: EditOption = .ShowDeleteButton
		presentController(withName: "EditInterface", context: [ "countdown" : countdown!, "options" : options.rawValue ])
		hasChange = true
	}
	
	@IBAction func deleteMenuAction() {
		WCSession.default().sendMessage(["action" : "delete", "identifier" : self.countdown!.identifier],
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
		NotificationCenter.default.addObserver(self, selector: #selector(didReceive(_:)), name: NSNotification.Name(rawValue: "CountdownDidUpdateNotification"), object: nil)
		
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
	}
	
	deinit {
		self.timer?.invalidate()
	}
}
