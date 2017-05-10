//
//  ThemeInterfaceController.swift
//  Closer
//
//  Created by Max on 26/09/15.
//
//

import WatchKit

class ThemeRowController: NSObject {
	
	@IBOutlet fileprivate var titleLabel: WKInterfaceLabel!
	@IBOutlet fileprivate var imageView: WKInterfaceImage!
	
	var title: String? {
		didSet { titleLabel.setText(title) }
	}
	
	var image: UIImage? {
		didSet { imageView.setImage(image) }
	}
}

class ThemeInterfaceController: WKInterfaceController {
	
	@IBOutlet var tableView: WKInterfaceTable!
	
	var options: EditOption?
	fileprivate var countdown: Countdown!
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		countdown = context as! Countdown
	}
	
	func reloadData() {
		let styles = ColorStyle.styles
		tableView.setNumberOfRows(styles.count, withRowType: "ThemeIdentifier")
		var index = 0
		for style in styles {
			let rowController = tableView.rowController(at: index) as! ThemeRowController
			rowController.title = style.name
			rowController.titleLabel.setTextColor((countdown?.style == style) ? .white : .gray)
			rowController.imageView.setTintColor(UIColor(colorStyle: style))
			rowController.image = #imageLiteral(resourceName: "theme-row-accessory")
			index += 1
		}
		tableView.scrollToRow(at: Int(countdown!.style.rawValue))
	}
	
	override func willActivate() {
		super.willActivate()
		reloadData()
	}
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		countdown.style = ColorStyle(rawValue: UInt(rowIndex))!
		dismiss()
	}
}
