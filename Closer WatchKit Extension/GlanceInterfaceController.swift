//
//  GlanceInterfaceController.swift
//  Closer
//
//  Created by Max on 27/05/15.
//
//

import WatchKit
import Foundation
import WatchConnectivity

class GlanceInterfaceController: WKInterfaceController, WCSessionDelegate {
	/** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
	@available(watchOS 2.2, *)
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

	
	@IBOutlet var titleLabel: WKInterfaceLabel!
	@IBOutlet var imageView: WKInterfaceImage!
	@IBOutlet var timerLabel: WKInterfaceTimer!
	@IBOutlet var descriptionLabel: WKInterfaceLabel!
	@IBOutlet var detailsLabel: WKInterfaceLabel!
	var endDate: Date?
	
	override init() {
		super.init()
		
		let session = WCSession.default()
		session.delegate = self
		session.activate()
	}
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
	}
	
	func update () {

		let userDefaults = UserDefaults(suiteName: "group.lisacintosh.closer")!
		let glanceType = GlanceType(string: userDefaults.string(forKey: "glance_type"))
		let countdown = Countdown.countdownWith(glanceType)
		if (countdown != nil) {
			endDate = countdown!.endDate
			let color = UIColor(colorStyle: countdown!.style)
			titleLabel.setTextColor(color)
			titleLabel.setText(countdown!.name)
			if (countdown!.type == .timer) {
				
				let index = countdown!.durationIndex!
				let durations = countdown!.durations!
				if (durations.count > 0) {
					let duration = durations[index]
					if (endDate != nil) {
						timerLabel.setDate(endDate!)
					} else {
						timerLabel.setDate(Date(timeIntervalSinceNow: duration))
					}
					timerLabel.setTextColor(color)
					
					imageView.setImage(countdown!.progressionImageWithSize(CGSize(width: 74, height: 74), cornerRadius: 74/2))
					
					// "of [total duration]"
					var components = DateComponents()
					components.second = Int(duration)
					let calendar = Calendar.current
					let date = calendar.date(from: components)
					descriptionLabel.setText("of \(DateFormatter.localizedString(from: date!, dateStyle: .none, timeStyle: .medium))")
					
					if (durations.count > 1) {
						// "Next: [next duration]"
						var nextComponents = DateComponents()
						nextComponents.second = Int(durations[(index+1) % durations.count])
						let nextDate = calendar.date(from: nextComponents)
						detailsLabel.setText("Next: \(DateFormatter.localizedString(from: nextDate!, dateStyle: .none, timeStyle: .medium))")
					}
					detailsLabel.setHidden(durations.count < 2) // Hide only one or no durations
				}
			} else {
				if (endDate != nil) {
					timerLabel.setDate(endDate!)
					timerLabel.setTextColor(color)
					
					imageView.setImage(countdown!.progressionImageWithSize(CGSize(width: 74, height: 74), cornerRadius: 14))
					
					let formatter = DateFormatter()
					formatter.dateStyle = .medium
					// "before [end date]"
					descriptionLabel.setText("before \(formatter.string(from: endDate!))")
				}
				detailsLabel.setHidden(true)
			}
			
		} else { // No countdowns, show error message
			titleLabel.setText("No Countdowns")
			detailsLabel.setHidden(true)
		}
		
		timerLabel.setHidden(countdown == nil)
		descriptionLabel.setHidden(countdown == nil)
	}
	
	override func willActivate() {
		super.willActivate()
		
		update()
		if (endDate != nil && endDate!.timeIntervalSinceNow >= 0.0) {
			timerLabel.start()
		} else {
			timerLabel.stop()
		}
	}
	
	override func didDeactivate() {
		super.didDeactivate()
		timerLabel.stop()
		NotificationCenter.default.removeObserver(self)
	}
}
