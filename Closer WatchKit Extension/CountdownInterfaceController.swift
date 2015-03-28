//
//  CountdownInterfaceController.swift
//  TestWatch
//
//  Created by Max on 14/03/15.
//  Copyright (c) 2015 lis@cintosh. All rights reserved.
//

import WatchKit
import Foundation
import CoreText


class CountdownInterfaceController: WKInterfaceController, ContextProtocol {
	
	@IBOutlet weak var image : WKInterfaceImage!
	var endDate:NSDate?
	var colorStyle:ColorStyle = .ColorStyleNight
	var identifier: String = ""
	
	var context: AnyObject? = nil
	
	override func awakeWithContext(context: AnyObject?) {
		super.awakeWithContext(context)
		self.context = context
		
		let dictContext:[String : AnyObject] = context as Dictionary
		self.setTitle(dictContext["name"] as? String)
		endDate = dictContext["endDate"] as? NSDate
		colorStyle = ColorStyle.fromString(dictContext["style"] as String)
		identifier = dictContext["identifier"] as String
		
		// @TODO: Update only when changes to display
		NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateUI"), userInfo: nil, repeats: true)
		updateUI()
		
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
		
		/*  pt1 --- pt2  */
		/*	 |       |   */
		/*  pt3 --- pt4  */
		
		let cornerRadius:CGFloat = 24.0
		let pt1:CGPoint = CGPointMake(cornerRadius + border, border)
		let pt2:CGPoint = CGPointMake(frame.width - cornerRadius - border, border)
		let pt3:CGPoint = CGPointMake(cornerRadius + border, frame.height - border)
		let pt4:CGPoint = CGPointMake(frame.width - cornerRadius - border, frame.height - border)
		
		CGContextMoveToPoint(bitmapContext, center.x + border * 2.0, pt1.y)
		CGContextAddLineToPoint(bitmapContext, pt2.x, pt2.y)
		CGContextAddArcToPoint(bitmapContext, pt2.x + cornerRadius, pt2.y, pt4.x + cornerRadius, pt4.y, cornerRadius)
		CGContextAddArcToPoint(bitmapContext, pt4.x + cornerRadius, pt4.y, pt4.x, pt4.y, cornerRadius)
		CGContextAddLineToPoint(bitmapContext, pt3.x, pt3.y)
		CGContextAddArcToPoint(bitmapContext, pt3.x - cornerRadius, pt3.y, pt1.x - cornerRadius, pt1.y, cornerRadius)
		CGContextAddArcToPoint(bitmapContext, pt1.x - cornerRadius, pt1.y, pt1.x, pt1.y, cornerRadius)
		CGContextAddLineToPoint(bitmapContext, center.x - border * 2.0, pt1.y)
		var path:CGPath = CGContextCopyPath(bitmapContext)
		
		let color:UIColor = UIColor(colorStyle: colorStyle)
		
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 2.0)
		CGContextSetStrokeColorWithColor(bitmapContext, color.colorWithAlphaComponent(0.5).CGColor)
		CGContextStrokePath(bitmapContext)
		
		var seconds:NSTimeInterval = 0
		if (endDate != nil) {
			seconds = max(floor(endDate!.timeIntervalSinceNow), 0)
		}
		
		// @TODO: Stop if seconds <= 0
		
		let progression:CGFloat = 1.0 - (CGFloat(log(seconds / (60.0 * M_E))) - 1.0) / 14.0;
		let pathLength:CGFloat = (frame.height - 2.0 * border - 2.0 * cornerRadius) * 4.0 + 2.0 * CGFloat(M_PI) * cornerRadius
		var lengths:[CGFloat] = [ progression * pathLength, CGFloat.max ]
		var transform:CGAffineTransform = CGAffineTransformIdentity
		var dashingPath:CGPath = CGPathCreateCopyByDashingPath(path, &transform, 0.0, &lengths, UInt(lengths.count))
		
		CGContextBeginPath(bitmapContext)
		CGContextAddPath(bitmapContext, dashingPath)
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 4.0)
		CGContextSetStrokeColorWithColor(bitmapContext, UIColor.blackColor().CGColor)
		CGContextStrokePath(bitmapContext)
		
		CGContextBeginPath(bitmapContext)
		CGContextAddPath(bitmapContext, dashingPath)
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
		
		let days = floor(seconds / (24 * 60 * 60)); seconds -= days * (24 * 60 * 60)
		let hours = floor(seconds / (60 * 60)); seconds -= hours * (60 * 60)
		let minutes = floor(seconds / 60); seconds -= minutes * 60
		var count = seconds
		var description = "seconds"
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
		
		var string:NSAttributedString = NSAttributedString(string: UInt(count).description, attributes: attributes)
		var line:CTLineRef = CTLineCreateWithAttributedString(string as CFAttributedStringRef)
		let flush:CGFloat = 0.5 // Centered
		var offset = CTLineGetPenOffsetForFlush(line, flush, Double(frame.size.width))
		var bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions(0))
		var y = ceil((frame.size.height - bounds.size.height) / 2.0) - bounds.origin.y
		CGContextSetTextPosition(bitmapContext, CGFloat(offset), y)
		CTLineDraw(line, bitmapContext)
		
		// Description label
		attributes = [
			NSForegroundColorAttributeName : color.colorWithAlphaComponent(0.5),
			NSFontAttributeName : UIFont.systemFontOfSize(18.0) ]
		string = NSAttributedString(string: description, attributes: attributes)
		
		line = CTLineCreateWithAttributedString(string as CFAttributedStringRef)
		offset = CTLineGetPenOffsetForFlush(line, flush, Double(frame.size.width))
		bounds = CTLineGetImageBounds(line, bitmapContext)
		y -= bounds.size.height + 4.0
		CGContextSetTextPosition(bitmapContext, CGFloat(offset), y)
		CTLineDraw(line, bitmapContext)
		
		image.setImage(UIGraphicsGetImageFromCurrentImageContext())
		UIGraphicsEndImageContext()
	}
	
	@IBAction func infoMenuAction() {
		self.presentControllerWithName("CountdownDetails", context: self.context);
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
