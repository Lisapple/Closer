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
	fileprivate var lastModifiedPicker: WKInterfacePicker?
	
	fileprivate var hour: Int = 0, minute: Int = 0, day: Int = 0, month: Int = 0, year: Int = 0
	fileprivate var countdown: Countdown?
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		self.countdown = context as? Countdown
		
		setTitle(NSLocalizedString("generic.done", comment: ""))
		
		let calendar = Calendar.current
		let comps = (calendar as NSCalendar).components([.minute, .hour, .day, .month, .year], from: (self.countdown!.endDate != nil) ? self.countdown!.endDate! as Date : Date())
		hour = comps.hour!; minute = comps.minute! + 1; day = comps.day!; month = comps.month!; year = comps.year!
		
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
			item.title = "\(day)"
			daysItems.append(item)
		}
		daysPicker.setItems(daysItems)
		
		// Month
		let months = NSLocalizedString("months.names", comment: "").components(separatedBy: ",")
		let monthsItems = months.map { month -> WKPickerItem in
			let item = WKPickerItem()
			item.title = month
			return item
		}
		monthsPicker.setItems(monthsItems)
		
		// Year
		var yearsItems = [WKPickerItem]()
		let currentYear = (calendar as NSCalendar).component(.year, from: Date())
		for year in currentYear ... currentYear+5 {
			let item = WKPickerItem()
			item.title = "\(year-2000)"
			yearsItems.append(item)
		}
		yearsPicker.setItems(yearsItems)
		
		update()
		
		// @TODO: Clip to minimum(+ 1 minute)/maximum date
		// @TODO: On picker change, set to valid date
	}
	
	func update() {
		DispatchQueue.main.async { () -> Void in
			var comps = DateComponents()
			comps.hour = self.hour; comps.minute = self.minute; comps.second = 0
			comps.day = self.day; comps.month = self.month
			let currentYear = (Calendar.current as NSCalendar).component(.year, from: Date())
			comps.year = min(self.year, currentYear+5)
			
			let calendar = Calendar.current
			var date = calendar.date(from: comps)!
			date = (date.timeIntervalSinceNow > 0) ? date : Date(timeIntervalSinceNow: 60)
			comps = (calendar as NSCalendar).components([.day, .month, .year], from: date)
			self.day = comps.day!; self.month = comps.month!; self.year = comps.year!
			
			let pickers = [ self.daysPicker!, self.monthsPicker!, self.daysPicker! ]
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
	
	@IBAction func minutesPickerAction(_ index: Int) {
		if (index != minute) {
			minute = index
			update() }
	}
	@IBAction func hoursPickerAction(_ index: Int) {
		if (index != hour) {
			hour = index
			update() }
	}
	
	@IBAction func daysPickerAction(_ index: Int) {
		if (index != day) {
			day = index + 1
			lastModifiedPicker = daysPicker
			update() }
	}
	
	@IBAction func monthsPickerAction(_ index: Int) {
		if (index != month) {
			month = index + 1
			lastModifiedPicker = monthsPicker
			update() }
	}
	
	@IBAction func yearsPickerAction(_ index: Int) {
		if (index != year) {
			let currentYear = (Calendar.current as NSCalendar).component(.year, from: Date())
			year = currentYear + index
			lastModifiedPicker = yearsPicker
			update() }
	}
}
