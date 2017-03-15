//
//  DurationsInterfaceController.swift
//  Closer
//
//  Created by Max on 26/09/15.
//
//

import WatchKit

extension WKPickerItem {
	
	convenience init(title: String) {
		self.init()
		self.title = title
	}
}

class DurationInterfaceController: WKInterfaceController {
	
	@IBOutlet var label: WKInterfaceLabel!
	@IBOutlet var secondsPicker: WKInterfacePicker!
	@IBOutlet var minutesPicker: WKInterfacePicker!
	@IBOutlet var hoursPicker: WKInterfacePicker!
	@IBOutlet var daysPicker: WKInterfacePicker!
	
	fileprivate var countdown: Countdown?
	fileprivate var durationIndex: Int?
	
	fileprivate var seconds: Int = 0, minutes: Int = 0, hours: Int = 0, days: Int = 0
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		setTitle("Done")
		
		let contextDict = context as? [String : AnyObject]
		self.countdown = contextDict!["countdown"] as? Countdown
		durationIndex = contextDict!["durationIndex"] as? Int
		label.setText("Duration #\(durationIndex!+1)")
		
		seconds = Int(countdown!.durations![durationIndex!])
		
		var daysItems = [WKPickerItem]()
		for day in 0 ..< 6 {
			let title = "\(day) " + ((day == 1) ? "day" : "days")
			daysItems.append(WKPickerItem(title: title))
		}
		daysPicker.setItems(daysItems)
		days = Int(seconds / (24 * 60 * 60))
		seconds -= days * 24 * 60 * 60
		daysPicker.setSelectedItemIndex(days)
		
		var hoursItems = [WKPickerItem]()
		for hour in 0 ..< 24 {
			let title = "\(hour) " + ((hour == 1) ? "hour" : "hours")
			hoursItems.append(WKPickerItem(title: title))
		}
		hoursPicker.setItems(hoursItems)
		hours = Int(seconds / (60 * 60))
		seconds -= hours * 60 * 60
		hoursPicker.setSelectedItemIndex(hours)
		
		var minutesItems = [WKPickerItem]()
		for minute in 0 ..< 60 {
			let title = "\(minute) " + ((minute == 1) ? "minute" : "minutes")
			minutesItems.append(WKPickerItem(title: title))
		}
		minutesPicker.setItems(minutesItems)
		minutes = Int(seconds / 60)
		seconds -= minutes * 60
		minutesPicker.setSelectedItemIndex(minutes)
		
		var secondsItems = [WKPickerItem]()
		for second in 0 ..< 60 {
			let title = "\(second) " + ((second == 1) ? "second" : "seconds")
			secondsItems.append(WKPickerItem(title: title))
		}
		secondsPicker.setItems(secondsItems)
		secondsPicker.setSelectedItemIndex(seconds)
		secondsPicker.focus()
	}
	
	@IBAction func daysPickerAction(_ index: Int) { days = index }
	@IBAction func hoursPickerAction(_ index: Int) { hours = index }
	@IBAction func minutesPickerAction(_ index: Int) { minutes = index }
	@IBAction func secondsPickerAction(_ index: Int) { seconds = index }
	
	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
		super.willActivate()
		
		let duration = ((days * 24 + hours * 60) + minutes) * 60 + seconds
		countdown!.durations![durationIndex!] = TimeInterval(duration)
	}
	
	override func willDisappear() {
		super.willDisappear()
	}
	
	override func didDeactivate() {
		// This method is called when watch view controller is no longer visible
		super.didDeactivate()
	}
}
