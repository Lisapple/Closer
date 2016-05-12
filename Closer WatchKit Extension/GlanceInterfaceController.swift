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
	
	@IBOutlet var titleLabel: WKInterfaceLabel!
	@IBOutlet var imageView: WKInterfaceImage!
	@IBOutlet var timerLabel: WKInterfaceTimer!
	@IBOutlet var descriptionLabel: WKInterfaceLabel!
	@IBOutlet var detailsLabel: WKInterfaceLabel!
	var endDate: NSDate?
	
	override init() {
		super.init()
		
		let session = WCSession.defaultSession()
		session.delegate = self
		session.activateSession()
	}
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
	}
	
	func update () {

		let userDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
		let glanceType = GlanceType(string: userDefaults.stringForKey("glance_type"))
		let countdown = Countdown.countdownWith(glanceType)
		if (countdown != nil) {
			endDate = countdown!.endDate
			let color = UIColor(colorStyle: countdown!.style)
			titleLabel.setTextColor(color)
			titleLabel.setText(countdown!.name)
			if (countdown!.type == .Timer) {
				
				let index = countdown!.durationIndex!
				let durations = countdown!.durations!
				if (durations.count > 0) {
					let duration = durations[index]
					if (endDate != nil) {
						timerLabel.setDate(endDate!)
					} else {
						timerLabel.setDate(NSDate(timeIntervalSinceNow: duration))
					}
					timerLabel.setTextColor(color)
					
					imageView.setImage(countdown!.progressionImageWithSize(CGSizeMake(74, 74), cornerRadius: 74/2))
					
					// "of [total duration]"
					let components = NSDateComponents()
					components.second = Int(duration)
					let calendar = NSCalendar.currentCalendar()
					let date = calendar.dateFromComponents(components)
					descriptionLabel.setText("of \(NSDateFormatter.localizedStringFromDate(date!, dateStyle: .NoStyle, timeStyle: .MediumStyle))")
					
					if (durations.count > 1) {
						// "Next: [next duration]"
						let nextComponents = NSDateComponents()
						nextComponents.second = Int(durations[(index+1) % durations.count])
						let nextDate = calendar.dateFromComponents(nextComponents)
						detailsLabel.setText("Next: \(NSDateFormatter.localizedStringFromDate(nextDate!, dateStyle: .NoStyle, timeStyle: .MediumStyle))")
					}
					detailsLabel.setHidden(durations.count < 2) // Hide only one or no durations
				}
			} else {
				if (endDate != nil) {
					timerLabel.setDate(endDate!)
					timerLabel.setTextColor(color)
					
					imageView.setImage(countdown!.progressionImageWithSize(CGSizeMake(74, 74), cornerRadius: 14))
					
					let formatter = NSDateFormatter()
					formatter.dateStyle = .MediumStyle
					// "before [end date]"
					descriptionLabel.setText("before \(formatter.stringFromDate(endDate!))")
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
		NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
