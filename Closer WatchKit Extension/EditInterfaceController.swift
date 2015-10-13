//
//  EditInterfaceController.swift
//  Closer
//
//  Created by Max on 26/09/15.
//
//

import WatchKit
import Foundation
import WatchConnectivity

struct EditOption : OptionSetType {
	
	let rawValue: Int
	init(rawValue: Int) { self.rawValue = rawValue }
	
	static var ShowCancelButton = EditOption(rawValue: 1 << 1)
	static var ShowDoneButton = EditOption(rawValue: 1 << 2)
	static var ShowDeleteButton = EditOption(rawValue: 1 << 3)
}

class DetailsRowController: NSObject {
	
	@IBOutlet private var titleLabel: WKInterfaceLabel!
	@IBOutlet private var detailsLabel: WKInterfaceLabel!
	
	var title: String? {
		didSet { titleLabel.setText(title) }
	}
	
	var details: String? {
		didSet { detailsLabel.setText(details) }
	}
}

class EditInterfaceController: WKInterfaceController {
	
	@IBOutlet var tableView: WKInterfaceTable!
	
	var options: EditOption?
	private var countdown: Countdown?
	private var rowTypes: [String]?
	
	override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
		
		let contextDict = context as? [String : AnyObject]
		if (contextDict != nil) {
			self.countdown = contextDict!["countdown"] as? Countdown
			if (contextDict!["options"] is Int) {
				self.options = EditOption(rawValue: contextDict!["options"] as! Int)
			}
		}
		
		if (options != nil) {
			if (options!.contains(.ShowDoneButton)) {
				setTitle("Done")
			} else if (options!.contains(.ShowCancelButton)) {
				setTitle("Cancel")
			}
		}
	}
	
	func reloadData() {
		rowTypes = ["TypeIdentifier", "NameIdentifier"]
		if (countdown?.type == .Timer) {
			rowTypes!.append("DurationsIdentifier") }
		else {
			rowTypes!.append("EndDateIdentifier")
			if (countdown?.message != nil && !(countdown!.message!.isEmpty)) {
				rowTypes!.append("MessageIdentifier") }
		}
		rowTypes!.append("StyleIdentifier")
		if (options != nil && options!.contains(.ShowDeleteButton)) {
			rowTypes!.append("DeleteIdentifier") }
		
		self.tableView.setRowTypes(rowTypes!)
		for index in 0 ..< rowTypes!.count {
			let rowController = self.tableView.rowControllerAtIndex(index) as? DetailsRowController
			//rowController?.details = rowTypes[index]
			switch rowTypes![index] {
				case "TypeIdentifier": rowController?.details = (countdown?.type == .Timer) ? "Timer" : "Countdown"
				case "NameIdentifier": rowController?.details = countdown?.name
				case "EndDateIdentifier":
					if (countdown?.endDate != nil) {
						let formatter = NSDateFormatter()
						formatter.dateStyle = .ShortStyle
						formatter.timeStyle = .ShortStyle
						rowController?.details = formatter.stringFromDate(countdown!.endDate!)
						rowController?.detailsLabel.setTextColor(UIColor.grayColor())
					} else {
						rowController?.details = "No date"
						rowController?.detailsLabel.setTextColor(UIColor.redColor()) }
				case "MessageIdentifier": rowController?.details = countdown?.message
			case "DurationsIdentifier" : rowController?.details = (countdown?.durations != nil) ? "\(countdown!.durations!.count)" : "None"
				case "StyleIdentifier": rowController?.details = countdown?.style.toString()!.capitalizedString
				default: break
			}
		}
	}
	
	override func willActivate() {
		super.willActivate()
		reloadData()
	}
	
	override func didAppear() {
		super.didAppear()
	}
	
	override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
		switch rowTypes![rowIndex] {
			case "TypeIdentifier":		setTypeAction()
			case "NameIdentifier":		setNameAction()
			case "EndDateIdentifier":	setEndDateAction()
			case "MessageIdentifier":	setMessageAction()
			case "DurationsIdentifier": setDurationsAction()
			case "StyleIdentifier":		setStyleAction()
			case "DeleteIdentifier":	deleteAction()
			default: break
		}
	}
	
	func setTypeAction() {
		
		pushControllerWithName("EditInterface", context: countdown)
		
		let message = "Countdown for remaining duration until a date, or timer for specific durations";
		presentAlertControllerWithTitle("", message: message, preferredStyle: .ActionSheet, actions: [
			WKAlertAction(title: "Countdown", style: WKAlertActionStyle.Default, handler: { () -> Void in
				self.countdown?.type = .Countdown; }),
			WKAlertAction(title: "Timer", style: WKAlertActionStyle.Default, handler: { () -> Void in
				self.countdown?.type = .Timer; })
		])
	}
	
	func setNameAction() {
		presentTextInputControllerWithSuggestions(nil, allowedInputMode: .Plain) { (results : [AnyObject]?) -> Void in
			if (results?.first as? String != nil) {
				self.countdown!.name = results?.first as! String
			} }
	}
	
	func setEndDateAction() {
		presentControllerWithName("DatePicker", context: countdown!)
	}
	
	func setMessageAction() {
		presentTextInputControllerWithSuggestions(nil, allowedInputMode: .Plain) { (results : [AnyObject]?) -> Void in
			if (results?.first as? String != nil) {
				self.countdown!.message = results?.first as? String
			} }
	}

	func setDurationsAction() {
		let count = countdown!.durations?.count
		if (count != nil && count > 0) {
			let names = [String](count: count!, repeatedValue: "DurationInterface")
			var contexts = [[String : AnyObject]]()
			for index in 0 ..< count! {
				contexts.append([ "countdown" : countdown!, "durationIndex" : index ])
			}
			presentControllerWithNames(names, contexts: contexts)
		} else {
			// Show "No durations" page (with intructions to add duration on iPhone app)
			presentControllerWithName("DurationInterface", context: nil)
		}
	}
	
	func setStyleAction() {
		presentControllerWithName("ThemeInterface", context: countdown)
	}
	
	func deleteAction() {
		let title = "Delete this " + ((countdown?.type == .Timer) ? "timer" : "countdown") + "?"
		presentAlertControllerWithTitle(title, message: nil, preferredStyle: .ActionSheet, actions: [
			WKAlertAction(title: "Delete", style: .Destructive, handler: { () -> Void in
				WCSession.defaultSession().sendMessage(["action" : "delete", "identifier" : self.countdown!.identifier],
					replyHandler: { (replyInfo: [String : AnyObject]) -> Void in
						self.dismissController()
					}, errorHandler: nil)
			}),
			WKAlertAction(title: "Cancel", style: .Cancel, handler: { () -> Void in })
		])
	}

    override func didDeactivate() {
		//let userInfo = [String : AnyObject]()
		//updateUserActivity("com.lisacintosh.closer.update-countdown", userInfo: userInfo, webpageURL: nil)
		
		let data = try? NSJSONSerialization.dataWithJSONObject(self.countdown!.toDictionary(), options: NSJSONWritingOptions(rawValue: 0))
		WCSession.defaultSession().sendMessage(["action" : "update", "identifier" : countdown!.identifier, "data" : data!],
			replyHandler: { (replyInfo: [String : AnyObject]) -> Void in
				print(replyInfo)
			}) { (error: NSError) -> Void in
				print(error)
		}
		
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
