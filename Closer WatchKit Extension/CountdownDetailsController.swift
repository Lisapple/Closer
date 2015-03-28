//
//  CountdownDetailsController.swift
//  Closer
//
//  Created by Max on 25/03/15.
//
//

import WatchKit
import Foundation


class CountdownDetailsController: WKInterfaceController {
	
	@IBOutlet weak var label : WKInterfaceLabel!
	@IBOutlet weak var date : WKInterfaceLabel!
	@IBOutlet weak var message : WKInterfaceLabel!
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		
		let contextDict = context as [String : AnyObject]
		label.setText(contextDict["name"] as? String)
		let endDate = contextDict["endDate"] as? NSDate
		var formatter = NSDateFormatter()
		formatter.dateStyle = .ShortStyle
		formatter.timeStyle = .ShortStyle
		date.setText(formatter.stringFromDate(endDate!))
		message.setText(contextDict["message"] as? String)
	}
}