//
//  TimerDetailsController.swift
//  Closer
//
//  Created by Max on 25/03/15.
//
//

import WatchKit
import Foundation


extension NSNumber {
	var localizedDurationDescription: String {
		var seconds: Double = self.doubleValue
		let days = floor(seconds / (24 * 60 * 60)); seconds -= days * (24 * 60 * 60)
		let hours = floor(seconds / (60 * 60)); seconds -= hours * (60 * 60)
		let minutes = floor(seconds / 60); seconds -= minutes * 60
		
		var components: [String] = []
		if days > 0    { components.append("\(UInt(days))d") }
		if hours > 0   { components.append("\(UInt(hours))h") }
		if minutes > 0 { components.append("\(UInt(minutes))m") }
		if seconds > 0 { components.append("\(UInt(seconds))s") }
		return NSArray(array: components).componentsJoinedByString(" ")
	}
}

class TimerDetailsRowController: NSObject {
	@IBOutlet weak var label : WKInterfaceLabel!
	
	func setText(text : String) {
		label.setText(text)
	}
}

class TimerDetailsController: WKInterfaceController {
	
	@IBOutlet weak var label : WKInterfaceLabel!
	@IBOutlet weak var table : WKInterfaceTable!
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		
		let contextDict = context as! [String : AnyObject]
		label.setText(contextDict["name"] as? String)
		let durations = contextDict["durations"] as! [NSNumber]
		table.setNumberOfRows(durations.count, withRowType: "TimerDurationRow")
		for i in 0..<durations.count {
			var row:TimerDetailsRowController = table.rowControllerAtIndex(i) as! TimerDetailsRowController
			row.setText(durations[i].localizedDurationDescription)
		}
	}
}