//
//  DatePickerInterfaceController.swift
//  Closer
//
//  Created by Max on 28/09/15.
//
//

import WatchKit

class DatePickerInterfaceController: WKInterfaceController {

	@IBOutlet var hoursPicker: WKInterfacePicker!
	@IBOutlet var minutesPicker: WKInterfacePicker!
	
	@IBOutlet var daysPicker: WKInterfacePicker!
	@IBOutlet var monthsPicker: WKInterfacePicker!
	@IBOutlet var yearsPicker: WKInterfacePicker!
	private var lastModifiedPicker: WKInterfacePicker?
	
	private var hour: Int = 0, minute: Int = 0, day: Int = 0, month: Int = 0, year: Int = 0
	private var countdown: Countdown?
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		
		self.countdown = context as? Countdown
		
		setTitle("Done")
		
		let calendar = NSCalendar.currentCalendar()
		let comps = calendar.components([.Minute, .Hour, .Day, .Month, .Year], fromDate: self.countdown!.endDate!)
		hour = comps.hour; minute = comps.hour; day = comps.day; month = comps.month; year = comps.year
		
		// Hour
		var hoursItems = [WKPickerItem]()
		for hour in 0 ... 23 {
			let item = WKPickerItem()
			//item.caption = "Hour"
			item.title = "\(hour)"
			hoursItems.append(item)
		}
		hoursPicker.setItems(hoursItems)
		hoursPicker.setSelectedItemIndex(hour)
		
		// Minute
		var minutesItems = [WKPickerItem]()
		for minute in 0 ..< 60 {
			let item = WKPickerItem()
			//item.caption = "Minute"
			item.title = (minute < 10) ? "0\(minute)" : "\(minute)"
			minutesItems.append(item)
		}
		minutesPicker.setItems(minutesItems)
		minutesPicker.setSelectedItemIndex(minute)
		
		// Day
		var daysItems = [WKPickerItem]()
		for day in 1 ... 31 {
			let item = WKPickerItem()
			//item.caption = "Day"
			item.title = "\(day)"
			daysItems.append(item)
		}
		daysPicker.setItems(daysItems)
		
		// Month
		let monthsItems = [ "Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec" ].map { (month: String) -> WKPickerItem in
			let item = WKPickerItem()
			//item.caption = "Hour" 
			item.title = month
			return item
		}
		monthsPicker.setItems(monthsItems)
		
		// Year
		var yearsItems = [WKPickerItem]()
		let currentYear = calendar.component(.Year, fromDate: NSDate())
		for year in currentYear ... currentYear+5 {
			let item = WKPickerItem()
			//item.caption = "Year"
			item.title = "\(year-2000)"
			yearsItems.append(item)
		}
		yearsPicker.setItems(yearsItems)
		
		update()
		
		// @TODO: Clip to minimum(+ 1 minute)/maximum date
		// @TODO: On picker change, set to valid date
	}
	
	func update() {
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			var comps = NSDateComponents()
			comps.hour = self.hour; comps.minute = self.minute; comps.second = 0
			comps.day = self.day; comps.month = self.month
			let currentYear = NSCalendar.currentCalendar().component(.Year, fromDate: NSDate())
			comps.year = min(self.year, currentYear+5)
			
			let calendar = NSCalendar.currentCalendar()
			var date = calendar.dateFromComponents(comps)!
			date = (date.timeIntervalSinceNow > 0) ? date : NSDate(timeIntervalSinceNow: 60)
			comps = calendar.components([.Day, .Month, .Year], fromDate: date)
			self.day = comps.day; self.month = comps.month; self.year = comps.year
			
			let pickers = [ self.daysPicker, self.monthsPicker, self.daysPicker ]
			_ = pickers.map { (picker: WKInterfacePicker!) -> Void in
				if (picker != self.lastModifiedPicker) {
					if /**/ (picker == self.daysPicker) {
						self.daysPicker.setSelectedItemIndex(self.day - 1) }
					else if (picker == self.monthsPicker) {
						self.monthsPicker.setSelectedItemIndex(self.month - 1) }
					else if (picker == self.yearsPicker) {
						self.yearsPicker.setSelectedItemIndex(self.year) }
				}
			}
			
			self.countdown!.endDate = date
		}
	}
	
	@IBAction func minutesPickerAction(index: Int) {
		if (index != minute) {
			minute = index
			update() }
	}
	@IBAction func hoursPickerAction(index: Int) {
		if (index != hour) {
			hour = index
			update() }
	}
	
	@IBAction func daysPickerAction(index: Int) {
		if (index != day) {
			day = index + 1
			lastModifiedPicker = daysPicker
			update() }
	}
	
	@IBAction func monthsPickerAction(index: Int) {
		if (index != month) {
			month = index + 1
			lastModifiedPicker = monthsPicker
			update() }
	}
	
	@IBAction func yearsPickerAction(index: Int) {
		if (index != year) {
			let currentYear = NSCalendar.currentCalendar().component(.Year, fromDate: NSDate())
			year = currentYear + index
			lastModifiedPicker = yearsPicker
			update() }
	}
}
