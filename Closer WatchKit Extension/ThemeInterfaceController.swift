//
//  ThemeInterfaceController.swift
//  Closer
//
//  Created by Max on 26/09/15.
//
//

import WatchKit

class ThemeRowController: NSObject {
	
	@IBOutlet private var titleLabel: WKInterfaceLabel!
	@IBOutlet private var imageView: WKInterfaceImage!
	
	var title: String? {
		didSet { titleLabel.setText(title) }
	}
	
	var image: UIImage? {
		didSet { imageView.setImage(image?.imageWithRenderingMode(.AlwaysTemplate)) }
	}
}

class ThemeInterfaceController: WKInterfaceController {
	
	@IBOutlet var tableView: WKInterfaceTable!
	
	var options: EditOption?
	private var countdown: Countdown?
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		
		countdown = context as? Countdown
	}
	
	func reloadData() {
		
		let count = Int(ColorStyle.NumberOfStyle.rawValue)
		tableView.setNumberOfRows(count, withRowType: "ThemeIdentifier")
		for index in 0 ..< count {
			let rowController = tableView.rowControllerAtIndex(index) as? ThemeRowController
			let colorStyle = ColorStyle(rawValue: UInt(index))
			rowController?.title = colorStyle?.toString()?.capitalizedString
			rowController?.titleLabel.setTextColor((countdown?.style == colorStyle) ? UIColor.whiteColor() : UIColor.grayColor())
			rowController?.imageView.setTintColor(UIColor(colorStyle: colorStyle!))
			rowController?.image = UIImage(named: "theme-row-accessory")
		}
		tableView.scrollToRowAtIndex(Int(countdown!.style.rawValue))
	}
	
	override func willActivate() {
		super.willActivate()
		reloadData()
	}
	
	override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
		countdown?.style = ColorStyle(rawValue: UInt(rowIndex))!
		dismissController()
	}
}
