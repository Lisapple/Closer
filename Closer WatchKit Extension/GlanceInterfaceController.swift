//
//  GlanceInterfaceController.swift
//  Closer
//
//  Created by Max on 27/05/15.
//
//

import WatchKit
import Foundation


class GlanceInterfaceController: WKInterfaceController {
	
	@IBOutlet var titleLabel: WKInterfaceLabel!
	@IBOutlet var imageView: WKInterfaceImage!
	@IBOutlet var timerLabel: WKInterfaceTimer!
	@IBOutlet var descriptionLabel: WKInterfaceLabel!
	@IBOutlet var detailsLabel: WKInterfaceLabel!
	var endDate: NSDate?
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
	}
	
	func update () {
		let userDefaults:NSUserDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
		let countdowns = userDefaults.arrayForKey("countdowns") as? [[String:AnyObject]]
		var countdown: [String:AnyObject]?
		if (countdowns != nil) {
			
			let glanceType = userDefaults.stringForKey("glance_type")
			if (glanceType == "closest_countdown") {
				// Get all countdowns sorted by endDate
				let sortedCountdowns = countdowns!.filter({ (countdown: [String : AnyObject]) -> Bool in
					return (countdown["type"] as! UInt == 0 /* Countdown */)
				}).sorted({ (countdown1: [String : AnyObject], countdown2: [String : AnyObject]) -> Bool in
					let endDate1 = countdown1["endDate"] as? NSDate
					let endDate2 = countdown2["endDate"] as? NSDate
					if (endDate2 != nil) {
						return (endDate1?.timeIntervalSinceDate(endDate2!) < 0) // Return true if endDate1 < endDate2 (i.e. endDate1 - endDate2 < 0)
					}
					return false
				})
				// Set |countdown| with the closest countdown to finish (if any)
				if (sortedCountdowns.first != nil) {
					let closestCountdown = sortedCountdowns.first! as [String:AnyObject]
					if (closestCountdown["endDate"] != nil) {
						countdown = closestCountdown
					}
				}
			}
			else if (glanceType == "closest_timer") {
				// Get all timers sorted by endDate
				let sortedTimers = countdowns!.filter({ (timer: [String : AnyObject]) -> Bool in
					return (timer["type"] as! UInt == 1 /* Timer */)
				}).sorted({ (timer1: [String : AnyObject], timer2: [String : AnyObject]) -> Bool in
					let endDate1 = timer1["endDate"] as? NSDate
					let endDate2 = timer2["endDate"] as? NSDate
					if (endDate2 != nil) {
						return (endDate1?.timeIntervalSinceDate(endDate2!) < 0) // Return true if endDate1 < endDate2 (i.e. endDate1 - endDate2 < 0)
					}
					return false
				})
				// Set |countdown| with the closest timer to finish (if any, find the timer with the shortest duration else)
				if (sortedTimers.first != nil) {
					let closestTimer = sortedTimers.first! as [String:AnyObject]
					if (closestTimer["endDate"] != nil) {
						countdown = closestTimer
					} else {
						let shortestTimers = sortedTimers.sorted({ (timer1: [String : AnyObject], timer2: [String : AnyObject]) -> Bool in
							let durationIndex1 = timer1["durationIndex"] as! Int
							let currentDuration1 = (timer1["durations"] as! [NSTimeInterval])[durationIndex1]
							let durationIndex2 = timer2["durationIndex"] as! Int
							let currentDuration2 = (timer2["durations"] as! [NSTimeInterval])[durationIndex2]
							return currentDuration1 < currentDuration2 // asc order
						})
						if (shortestTimers.first != nil) {
							countdown = shortestTimers.first
						}
					}
				}
			}
			if (glanceType == "last_selected" || countdown == nil) {
				let identifier = NSUserDefaults().stringForKey("selectedIdentifier")
				countdown = countdowns!.filter({ (countdown: [String : AnyObject]) -> Bool in
					return countdown["identifier"] as? String == identifier
				}).first
				if (countdown == nil) {
					countdown = countdowns?.first
				}
			}
		}
		
		if (countdown != nil) {
			endDate = countdown!["endDate"] as? NSDate
			
			let colorStyle: ColorStyle = ColorStyle.fromInt(countdown!["style"] as! Int)
			let color = UIColor(colorStyle: colorStyle)
			
			titleLabel.setTextColor(color)
			titleLabel.setText(countdown!["name"] as? String)
			let isTimer = (countdown!["type"] as! UInt == 1 /* Timer */)
			if (isTimer) {
				
				let index = countdown!["durationIndex"] as! Int
				let durations = countdown!["durations"] as! [NSTimeInterval]
				if (durations.count > 0) {
					let duration = durations[index]
					
					if (endDate != nil) {
						timerLabel.setDate(endDate!)
					} else {
						timerLabel.setDate(NSDate(timeIntervalSinceNow: duration))
					}
					timerLabel.setTextColor(color)
					
					let remaining = (endDate != nil) ? NSDate().timeIntervalSinceDate(endDate!) : 0.0
					let progression:Double = 1.0 - ((endDate != nil) ? endDate!.timeIntervalSinceNow : remaining) / duration
					imageView.setImage(progressionImage(CGSizeMake(74.0, 74.0), progression: CGFloat(progression), color: color, radius: 74.0 / 2.0))
					
					// "of [total duration]"
					let components = NSDateComponents()
					components.second = Int(duration)
					let calendar = NSCalendar.currentCalendar()
					let date = calendar.dateFromComponents(components)
					descriptionLabel.setText("of \(NSDateFormatter.localizedStringFromDate(date!, dateStyle: .NoStyle, timeStyle: .MediumStyle))")
					
					if (durations.count > 1) {
						// "Next: [next duration]"
						let nextComponents = NSDateComponents()
						nextComponents.second = Int(durations[(index+1) % durations.count])
						let nextDate = calendar.dateFromComponents(nextComponents)
						detailsLabel.setText("Next: \(NSDateFormatter.localizedStringFromDate(nextDate!, dateStyle: .NoStyle, timeStyle: .MediumStyle))")
					}
					detailsLabel.setHidden(durations.count < 2)
				}
			} else {
				if (endDate != nil) {
					let seconds = max(floor(endDate!.timeIntervalSinceNow), 0)
					let progression: CGFloat = 1.0 - (CGFloat(log(seconds / (60.0 * M_E))) - 1.0) / 14.0;
					imageView.setImage(progressionImage(CGSizeMake(74.0, 74.0), progression: 0.5, color: color, radius: 14.0))
					
					timerLabel.setDate(endDate!)
					timerLabel.setTextColor(color)
					
					let formatter = NSDateFormatter()
					formatter.dateStyle = .MediumStyle
					// "before [end date]"
					descriptionLabel.setText("before \(formatter.stringFromDate(endDate!))")
				}
				detailsLabel.setHidden(true)
			}
			
		} else { // No countdowns, show error message
			titleLabel.setText("No Countdowns")
		}
		
		timerLabel.setHidden(countdown == nil)
		descriptionLabel.setHidden(countdown == nil)
    }
	
	func progressionImage(size: CGSize, progression: CGFloat, color: UIColor, radius: CGFloat) -> UIImage {
		let frame:CGRect = CGRectMake(0.0, 0.0, size.width, size.width)
		UIGraphicsBeginImageContextWithOptions(frame.size, false /* non-opaque */, 0.0)
		
		let bitmapContext:CGContext = UIGraphicsGetCurrentContext()!
		let border:CGFloat = 2.0
		let diameter:CGFloat = frame.size.width - 3 * border
		let center:CGPoint = CGPointMake(frame.size.width / 2.0, frame.size.height / 2.0)
		
		/*  pt1 --- pt2  */
		/*	 |       |   */
		/*  pt3 --- pt4  */
		
		if (radius >= size.height / 2.0) { // Timer
			CGContextAddArc(bitmapContext, center.x, center.y, size.height / 2.0 - border,
				CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * 0.99 - M_PI_2), 0)
		} else { // Countdown
			let cornerRadius:CGFloat = radius
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
		}
		var path:CGPath = CGContextCopyPath(bitmapContext)
		
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 2.0)
		CGContextSetStrokeColorWithColor(bitmapContext, color.colorWithAlphaComponent(0.5).CGColor)
		CGContextStrokePath(bitmapContext)
		
		if (radius >= size.height / 2.0) { // Timer
			// @TODO: Clip progression minimum to get progress bar start
			CGContextAddArc(bitmapContext, center.x, center.y, size.height / 2.0 - border,
				CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * (Double(progression) * 0.98 + 0.01) - M_PI_2), 0)
			
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
		} else {
			let pathLength:CGFloat = (frame.height - 2.0 * border - 2.0 * radius) * 4.0 + 2.0 * CGFloat(M_PI) * radius
			var lengths:[CGFloat] = [ progression * pathLength, CGFloat.max ]
			var transform:CGAffineTransform = CGAffineTransformIdentity
			var dashingPath:CGPath = CGPathCreateCopyByDashingPath(path, &transform, 0.0, &lengths, Int(lengths.count))
			
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
		}
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
	
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
		
		update()
		if (endDate != nil) {
			timerLabel.start()
		} else {
			timerLabel.stop()
		}
		
		weak var _self_ = self
		NSNotificationCenter.defaultCenter().addObserverForName("Darwin_CountdownDidUpdateNotification", object: nil, queue: nil) {
			(notification) -> Void in _self_!.update() }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
		timerLabel.stop()
		NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
