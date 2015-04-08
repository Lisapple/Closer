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

class TimerInterfaceController: WKInterfaceController {
	
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
			self.updateUI()
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
		if (dictContext["durations"] != nil) {
			duration = (dictContext["durations"] as Array)[dictContext["durationIndex"] as Int]
		}
		endDate = dictContext["endDate"] as NSDate?
		self.paused = (endDate == nil)
		colorStyle = ColorStyle.fromString(dictContext["style"] as String)
		identifier = dictContext["identifier"] as String
		
		// @TODO: Update only when changes to display
		/*
		if (!paused) {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateUI", userInfo: nil, repeats: true)
				self.timer!.tolerance = 0.2
				self.paused = false;
			})
		}
		*/
		updateUI()
		
		if (paused) {
			addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Resume", action: "resumeMenuAction")
		} else {
			addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pauseMenuAction")
		}
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: "resetMenuAction")
		addMenuItemWithItemIcon(WKMenuItemIcon.Info, title: "Info", action: "infoMenuAction")
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: "deleteMenuAction")
		
		if (identifier == NSUserDefaults().stringForKey("selectedIdentifier")) {
			self.becomeCurrentPage()
		}
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
		// @TODO: Clip progression minimum to get progress bar start
		CGContextAddArc(bitmapContext, center.x, center.y, radius, CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * (progression * 0.98 + 0.01) - M_PI_2), 0)
		
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
			let seconds = endDate!.timeIntervalSinceNow
			if (seconds > 0.0) {
				let days = seconds / (24 * 60 * 60);
				let hours = seconds / (60 * 60);
				let minutes = seconds / 60;
				var count = seconds
				description = "seconds"
				if days >= 2 {
					count = ceil(days)
					description = "days"
				} else if hours >= 2 {
					count = ceil(hours)
					description = "hours"
				} else if minutes >= 2 {
					count = ceil(minutes)
					description = "minutes"
				}
				string = NSAttributedString(string: UInt(count).description, attributes: attributes)
			} else {
				attributes = [
					NSForegroundColorAttributeName : color,
					NSFontAttributeName : UIFont.systemFontOfSize(32.0) ]
				string = NSAttributedString(string: "Paused", attributes: attributes)
			}
		} else {
			attributes = [
				NSForegroundColorAttributeName : color,
				NSFontAttributeName : UIFont.systemFontOfSize(32.0) ]
			string = NSAttributedString(string: "Paused", attributes: attributes)
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
		
		if (!paused) {
			timer?.invalidate()
			timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateUI", userInfo: nil, repeats: false)
			timer!.tolerance = 0.2
		}
    }
	
	@IBAction func tooglePauseAction() {
		if (paused) {
			self.resumeMenuAction()
		} else {
			self.pauseMenuAction()
		}
	}
	
	@IBAction func pauseMenuAction() {
		/*
		if (!paused && endDate != nil) {
			remaining = endDate!.timeIntervalSinceNow
			endDate = nil
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer!.invalidate()
				self.timer = nil
			})
		}
		*/
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "pause"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
			println(replyInfo?["result"])
			self.paused = true;
			self.updateUI()
		}
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Play, title: "Resume", action: "resumeMenuAction")
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: "resetMenuAction")
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: "deleteMenuAction")
	}
	
	@IBAction func resumeMenuAction() {
		if (paused) {
			/*
			endDate = NSDate().dateByAddingTimeInterval(remaining)
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateUI", userInfo: nil, repeats: true)
				self.timer!.tolerance = 0.2
			})
			updateUI()
			*/
		}
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "resume"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
			println(replyInfo?["result"])
			self.paused = false;
			self.endDate = NSDate().dateByAddingTimeInterval((self.remaining > 0.0) ? self.remaining : self.duration)
			self.updateUI()
		}
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pauseMenuAction")
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: "resetMenuAction")
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: "deleteMenuAction")
	}
	
	@IBAction func resetMenuAction() {
		endDate = NSDate().dateByAddingTimeInterval(duration)
		/*
		if (self.timer?.valid == nil) {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateUI", userInfo: nil, repeats: true)
				self.timer!.tolerance = 0.2
				self.paused = false;
			})
		}
		*/
		updateUI()
		WKInterfaceController.openParentApplication(["identifier" : self.identifier, "action" : "reset"]) {
			(replyInfo:[NSObject : AnyObject]!, error:NSError!) -> Void in
				println(replyInfo?["result"])
		}
		
		clearAllMenuItems()
		addMenuItemWithItemIcon(WKMenuItemIcon.Pause, title: "Pause", action: "pauseMenuAction")
		addMenuItemWithImageNamed("reset-button", title: "Reset", action: "resetMenuAction")
		addMenuItemWithItemIcon(WKMenuItemIcon.Trash, title: "Delete", action: "deleteMenuAction")
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
		
		NSNotificationCenter.defaultCenter().addObserverForName("Darwin_CountdownDidUpdateNotification", object: nil, queue: nil) {
			(notification) -> Void in
			
			let userDefaults:NSUserDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
			var countdowns = userDefaults.arrayForKey("countdowns")! as [[String : AnyObject]]
			countdowns = countdowns.filter({ (countdown: [String : AnyObject]) -> Bool in
				return countdown["identifier"] as? String == self.identifier
			})
			
			if countdowns.first != nil {
				let countdown = countdowns.first! as [String : AnyObject]
				self.endDate = countdown["endDate"] as? NSDate
				let durations = countdown["durations"] as [NSTimeInterval]
				let index = countdown["durationIndex"] as NSNumber
				self.duration = durations[index.integerValue]
				self.paused = (self.endDate == nil)
				self.updateUI()
			}
		}
		
		NSUserDefaults().setObject(identifier, forKey: "selectedIdentifier");
    }

    override func didDeactivate() {
        super.didDeactivate()
		NSNotificationCenter.defaultCenter().removeObserver(self)
    }
	
	deinit {
		self.paused = true
		self.timer?.invalidate()
	}
}
