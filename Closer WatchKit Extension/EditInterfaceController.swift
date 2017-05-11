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

struct EditOption : OptionSet {
	
	let rawValue: Int
	init(rawValue: Int) { self.rawValue = rawValue }
	
	static var ShowAsCreate = EditOption(rawValue: 1 << 1) // For creating countdown, show the done button as "Create", shown as "Save" else
	static var ShowDeleteButton = EditOption(rawValue: 1 << 2)
}

class DetailsRowController: NSObject {
	
	@IBOutlet fileprivate var titleLabel: WKInterfaceLabel!
	@IBOutlet fileprivate var detailsLabel: WKInterfaceLabel!
	
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
	fileprivate var countdown: Countdown?
	fileprivate var rowTypes: [String]?
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		if let contextDict = context as? [String : AnyObject] {
			self.countdown = contextDict["countdown"] as? Countdown
			if let options = contextDict["options"] as? Int {
				self.options = EditOption(rawValue: options)
			}
		}
		setTitle("Cancel")
	}
	
	func reloadData() {
		rowTypes = ["TypeIdentifier", "NameIdentifier"]
		if (countdown?.type == .timer) {
			rowTypes!.append("DurationsIdentifier") }
		else {
			rowTypes!.append("EndDateIdentifier")
			if (countdown?.message != nil && !(countdown!.message!.isEmpty)) {
				rowTypes!.append("MessageIdentifier") }
		}
		rowTypes!.append("StyleIdentifier")
		if (options != nil && options!.contains(.ShowDeleteButton)) {
			rowTypes!.append("DeleteIdentifier") }
		
		if (options != nil && options!.contains(.ShowAsCreate)) {
			rowTypes!.append("CreateIdentifier") }
		else {
			rowTypes!.append("SaveIdentifier") }
		
		self.tableView.setRowTypes(rowTypes!)
		for index in 0 ..< rowTypes!.count {
			let rowController = self.tableView.rowController(at: index) as? DetailsRowController
			switch rowTypes![index] {
				case "TypeIdentifier": rowController!.details = LocalizedString((countdown?.type == .timer) ? "type.timer.name" : "type.countdown.name")
				case "NameIdentifier": rowController!.details = countdown?.name
				case "EndDateIdentifier":
					if (countdown?.endDate != nil) {
						let formatter = DateFormatter()
						formatter.dateStyle = .short
						formatter.timeStyle = .short
						rowController!.details = formatter.string(from: countdown!.endDate!)
						rowController!.detailsLabel.setTextColor(UIColor.gray)
					} else {
						rowController!.details = LocalizedString("label.no-date.name")
						rowController!.detailsLabel.setTextColor(UIColor.red) }
				case "MessageIdentifier": rowController!.details = countdown?.message
				case "DurationsIdentifier": rowController!.details = (countdown?.durations != nil) ? "\(countdown!.durations!.count)" : LocalizedString("duration.none")
				
				case "StyleIdentifier": rowController!.details = countdown?.style.name
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
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		switch rowTypes![rowIndex] {
			case "TypeIdentifier":	setTypeAction()
			case "NameIdentifier":	setNameAction()
			case "EndDateIdentifier":	setEndDateAction()
			case "MessageIdentifier":	setMessageAction()
			case "DurationsIdentifier": setDurationsAction()
			case "StyleIdentifier":	 setStyleAction()
			case "DeleteIdentifier": deleteAction()
			case "CreateIdentifier", "SaveIdentifier":
				saveAction()
			default: break
		}
	}
	
	func setTypeAction() {
		pushController(withName: "EditInterface", context: countdown)
		
		let actions = [
			WKAlertAction(title: LocalizedString("prompt.type.countdown.name"), style: .default,
			              handler: { _ in self.countdown?.type = .countdown; }),
			WKAlertAction(title: LocalizedString("prompt.type.timer.name"), style: .default,
			              handler: { _ in self.countdown?.type = .timer; }) ]
		presentAlert(withTitle: "", message: LocalizedString("prompt.type.message"),
		             preferredStyle: .actionSheet, actions: actions)
	}
	
	func setNameAction() {
		presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { (results : [Any]?) -> Void in
			if let result = results?.first as? String {
				self.countdown!.name = result
			}
		}
	}
	
	func setEndDateAction() {
		presentController(withName: "DatePicker", context: countdown!)
	}
	
	func setMessageAction() {
		presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { (results : [Any]?) -> Void in
			if let result = results?.first as? String {
				self.countdown!.message = result
			} }
	}

	func setDurationsAction() {
		if let count = countdown!.durations?.count, count > 0 {
			let names = [String](repeating: "DurationInterface", count: count)
			let contexts = (0..<count).map { [ "countdown" : countdown!, "durationIndex" : $0 ] }
			presentController(withNames: names, contexts: contexts)
		} else {
			// Show "No durations" page (with intructions to add duration on iPhone app)
			presentController(withName: "DurationInterface", context: nil)
		}
	}
	
	func setStyleAction() {
		presentController(withName: "ThemeInterface", context: countdown)
	}
	
	func deleteAction() {
		let title = LocalizedString((countdown?.type == .timer) ? "edit.delete.timer.name" : "edit.delete.countdown.name")
		presentAlert(withTitle: title, message: nil, preferredStyle: .actionSheet, actions: [
			WKAlertAction(title: LocalizedString("menu.action.delete"), style: .destructive, handler: { _ in
				let message = ["action" : "delete", "identifier" : self.countdown!.identifier]
				WCSession.default().sendMessage(message, replyHandler: { _ in self.dismiss() }, errorHandler: nil)
			}),
			WKAlertAction(title: LocalizedString("generic.cancel"), style: .cancel, handler: { _ in })
		])
	}
	
	func saveAction() {
		let data = try? JSONSerialization.data(withJSONObject: self.countdown!.toDictionary(), options: [])
		var message = ["action" : "update", "data" : data!] as [String : Any]
		if (self.options != nil && !self.options!.contains(.ShowAsCreate)) {
			message["identifier"] = countdown!.identifier }
		WCSession.default().sendMessage(message,
			replyHandler: { (replyInfo) in print(replyInfo) }) { (error) -> Void in print(error)
		}
	}
}
