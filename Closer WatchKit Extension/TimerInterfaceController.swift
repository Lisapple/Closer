//
//  PageInterfaceController.swift
//  TestWatch
//
//  Created by Max on 14/03/15.
//  Copyright (c) 2015 lis@cintosh. All rights reserved.
//

import WatchKit
import Foundation
import CoreText


protocol ContextProtocol {
	var context: AnyObject? { get set }
}

class TimerInterfaceController: WKInterfaceController, ContextProtocol {
	
	@IBOutlet weak var image: WKInterfaceImage!
	@IBOutlet weak var toogleButton: WKInterfaceButton!
	var identifier: String = ""
	var title: String = ""
	var endDate: NSDate?
	var remaining: NSTimeInterval = 0.0
	var duration: NSTimeInterval = 0.0
	var colorStyle: ColorStyle = .ColorStyleNight
	var timer: NSTimer?
	
	var _paused: Bool = false
	var paused: Bool {
		set {
			_paused = newValue
			toogleButton?.setTitle((paused) ? "Resume" : "Pause")
		}
		get {
			return _paused
		}
	}
	
	var context: AnyObject? = nil
	
	override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
		self.context = context
		
		let dictContext:[String : AnyObject] = context as Dictionary
		title = dictContext["name"] as String
		self.setTitle(self.title)
		duration = (dictContext["durations"] as Array)[dictContext["durationIndex"] as Int]
		endDate = dictContext["endDate"] as NSDate?
		self.paused = (endDate == nil)
		colorStyle = ColorStyle.fromString(dictContext["style"] as String)
		identifier = dictContext["identifier"] as String
		
		// @TODO: Update only when changes to display
		if (!paused) {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: true)
				self.timer!.tolerance = 0.2
				self.paused = false;
			})
		}
		updateUI()
		
		if (paused) {
			addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Resume", action: Selector("resumeMenuAction"))
		} else {
			addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: Selector("pauseMenuAction"))
		}
		addMenuItemWithItemIcon(WKMenuItemIcon.Block, title: "Reset", action: Selector("resetMenuAction")) // Replace the icon
		addMenuItemWithItemIcon(WKMenuItemIcon.Info, title: "Info", action: Selector("infoMenuAction"))
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: Selector("deleteMenuAction"))
	}
	
	func updateUI() {
		let frame:CGRect = CGRectMake(0.0, 0.0, self.contentFrame.size.width, self.contentFrame.size.width)
		UIGraphicsBeginImageContextWithOptions(frame.size, true, 0.0)
		
		let bitmapContext:CGContext = UIGraphicsGetCurrentContext()!
		let border:CGFloat = 2.0
		let diameter:CGFloat = frame.size.width - 3 * border
		let radius:CGFloat = ceil(diameter / 2.0)
		
		CGContextSaveGState(bitmapContext)
		let center:CGPoint = CGPointMake(frame.size.width / 2.0, frame.size.height / 2.0)
		CGContextAddArc(bitmapContext, center.x, center.y, radius, CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * 0.99 - M_PI_2), 0)
		
		let color:UIColor = UIColor(colorStyle: colorStyle)
		
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 2.0)
		CGContextSetStrokeColorWithColor(bitmapContext, color.colorWithAlphaComponent(0.5).CGColor)
		CGContextStrokePath(bitmapContext)
		
		let progression:Double = 1.0 - ((endDate != nil) ? endDate!.timeIntervalSinceNow : remaining) / duration
		CGContextAddArc(bitmapContext, center.x, center.y, radius, CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * progression * 0.99 - M_PI_2), 0)
		
		let path:CGPathRef = CGContextCopyPath(bitmapContext)
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 4.0)
		CGContextSetStrokeColorWithColor(bitmapContext, UIColor.blackColor().CGColor)
		CGContextStrokePath(bitmapContext)
		
		CGContextAddPath(bitmapContext, path)
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 2.0)
		CGContextSetStrokeColorWithColor(bitmapContext, color.CGColor)
		CGContextStrokePath(bitmapContext)
		CGContextRestoreGState(bitmapContext)
		
		CGContextTranslateCTM(bitmapContext, 0.0, frame.size.height)
		CGContextScaleCTM(bitmapContext, 1.0, -1.0)
		CGContextSetTextMatrix(bitmapContext, CGAffineTransformIdentity)
		
		// Number label
		var attributes:NSDictionary = [
			NSForegroundColorAttributeName : color,
			NSFontAttributeName : UIFont.systemFontOfSize(64.0) ]
		
		var string:NSAttributedString?
		var description:String?
		if (endDate != nil) {
			var seconds = endDate!.timeIntervalSinceNow
			let days = floor(seconds / (24 * 60 * 60)); seconds -= days * (24 * 60 * 60)
			let hours = floor(seconds / (60 * 60)); seconds -= hours * (60 * 60)
			let minutes = floor(seconds / 60); seconds -= minutes * 60
			var count = seconds
			description = "seconds"
			if days >= 3 {
				count = days
				description = "days"
			} else if hours >= 3 {
				count = hours
				description = "hours"
			} else if minutes >= 3 {
				count = minutes
				description = "minutes"
			}
			string = NSAttributedString(string: UInt(count).description, attributes: attributes)
		} else {
			attributes = [
				NSForegroundColorAttributeName : color,
				NSFontAttributeName : UIFont.systemFontOfSize(32.0) ]
			string = NSAttributedString(string: "Resume", attributes: attributes)
		}
		
		var line:CTLineRef = CTLineCreateWithAttributedString(string as CFAttributedStringRef!)
		let flush:CGFloat = 0.5 // Centered
		var offset = CTLineGetPenOffsetForFlush(line, flush, Double(frame.size.width))
		var bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions(0))
		var y = ceil((frame.size.height - bounds.size.height) / 2.0) - bounds.origin.y
		CGContextSetTextPosition(bitmapContext, CGFloat(offset), y)
		CTLineDraw(line, bitmapContext)
		
		if (description != nil) {
			// Description label
			attributes = [
				NSForegroundColorAttributeName : color.colorWithAlphaComponent(0.5),
				NSFontAttributeName : UIFont.systemFontOfSize(18.0) ]
			string = NSAttributedString(string: description!, attributes: attributes)
			line = CTLineCreateWithAttributedString(string as CFAttributedStringRef!)
			offset = CTLineGetPenOffsetForFlush(line, flush, Double(frame.size.width))
			bounds = CTLineGetImageBounds(line, bitmapContext)
			y -= bounds.size.height + 4.0
			CGContextSetTextPosition(bitmapContext, CGFloat(offset), y)
			CTLineDraw(line, bitmapContext)
		}

		image.setImage(UIGraphicsGetImageFromCurrentImageContext())
		UIGraphicsEndImageContext()
    }
	
	@IBAction func tooglePauseAction() {
		if (paused) {
			self.resumeMenuAction()
		} else {
			self.pauseMenuAction()
		}
	}
	
	@IBAction func pauseMenuAction() {
		if (!paused && endDate != nil) {
			remaining = endDate!.timeIntervalSinceNow
			endDate = nil
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer!.invalidate()
			})
		}
		updateUI()
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "pause"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
			println(replyInfo?["result"])
			self.paused = true;
		}
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Play, title: "Resume", action: Selector("resumeMenuAction"))
		addMenuItemWithItemIcon(WKMenuItemIcon.Block, title: "Reset", action: Selector("resetMenuAction")) // Replace the icon
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: Selector("deleteMenuAction"))
	}
	
	@IBAction func resumeMenuAction() {
		if (paused) {
			endDate = NSDate().dateByAddingTimeInterval(remaining)
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: true)
				self.timer!.tolerance = 0.2
			})
			updateUI()
		}
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "resume"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
				println(replyInfo?["result"])
			self.paused = false;
		}
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: Selector("pauseMenuAction"))
		addMenuItemWithItemIcon(WKMenuItemIcon.Block, title: "Reset", action: Selector("resetMenuAction")) // Replace the icon
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: Selector("deleteMenuAction"))
	}
	
	@IBAction func resetMenuAction() {
		if (self.timer?.valid == nil) {
			endDate = NSDate().dateByAddingTimeInterval(duration)
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: true)
				self.timer!.tolerance = 0.2
				self.paused = false;
			})
			updateUI()
		}
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "reset"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
				println(replyInfo?["result"])
		}
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: Selector("pauseMenuAction"))
		addMenuItemWithItemIcon(WKMenuItemIcon.Block, title: "Reset", action: Selector("resetMenuAction")) // Replace the icon
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: Selector("deleteMenuAction"))
	}
	
	@IBAction func infoMenuAction() {
		self.presentControllerWithName("TimerDetails", context: self.context);
	}
	
	@IBAction func deleteMenuAction() {
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "delete"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
			InterfaceController.reload()
		}
	}
	
    override func willActivate() {
        super.willActivate()
		updateUI()
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}
