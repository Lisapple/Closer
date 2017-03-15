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
		didSet { imageView.setImage(image?.withRenderingMode(.alwaysTemplate)) }
	}
}

class ThemeInterfaceController: WKInterfaceController {
	
	@IBOutlet var tableView: WKInterfaceTable!
	
	var options: EditOption?
	fileprivate var countdown: Countdown?
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		countdown = context as? Countdown
	}
	
	func reloadData() {
		
		let count = Int(ColorStyle.numberOfStyle.rawValue)
		tableView.setNumberOfRows(count, withRowType: "ThemeIdentifier")
		for index in 0 ..< count {
			let rowController = tableView.rowController(at: index) as? ThemeRowController
			let colorStyle = ColorStyle(rawValue: UInt(index))
			rowController?.title = colorStyle?.toString()?.capitalized
			rowController?.titleLabel.setTextColor((countdown?.style == colorStyle) ? UIColor.white : UIColor.gray)
			rowController?.imageView.setTintColor(UIColor(colorStyle: colorStyle!))
			rowController?.image = UIImage(named: "theme-row-accessory")
		}
		tableView.scrollToRow(at: Int(countdown!.style.rawValue))
	}
	
	override func willActivate() {
		super.willActivate()
		reloadData()
	}
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		countdown?.style = ColorStyle(rawValue: UInt(rowIndex))!
		dismiss()
	}
}
