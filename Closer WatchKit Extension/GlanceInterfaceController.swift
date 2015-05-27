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
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
	}
	
	func update () {
		let userDefaults:NSUserDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
		let countdowns = userDefaults.arrayForKey("countdowns") as? [[String:AnyObject]]
		var countdown: [String:AnyObject]?
		if (countdowns != nil) {
			let identifier = userDefaults.stringForKey("selectedIdentifier")
			countdown = countdowns!.filter({ (countdown: [String : AnyObject]) -> Bool in
				return countdown["identifier"] as? String == identifier
			}).first
			if (countdown == nil) {
				countdown = countdowns?.first
			}
		}
		
		if (countdown != nil) {
			
			// @TODO: Set text and progression with countdown/timer color
			// @TODO: Get change notification to update
			
			titleLabel.setText(countdown!["name"] as? String)
			let isTimer = (countdown!["type"] as! UInt == 1 /* Timer */)
			
			if (isTimer) {
				
				let index = countdown!["durationIndex"] as! Int
				let durations = countdown!["durations"] as! [NSTimeInterval]
				if (durations.count > 0) {
					let duration = durations[index]
					
					let endDate = countdown!["endDate"] as? NSDate
					if (endDate != nil) {
						timerLabel.setDate(endDate!)
					}
					
					let remaining = (endDate != nil) ? NSDate().timeIntervalSinceDate(endDate!) : 0.0
					let progression:Double = 1.0 - ((endDate != nil) ? endDate!.timeIntervalSinceNow : remaining) / duration
					imageView.setImage(progressionImage(CGSizeMake(74.0, 74.0), progression: CGFloat(progression), color: UIColor.whiteColor(), radius: 74.0 / 2.0))
					
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
				let endDate = countdown!["endDate"] as? NSDate
				if (endDate != nil) {
					let seconds = max(floor(endDate!.timeIntervalSinceNow), 0)
					let progression: CGFloat = 1.0 - (CGFloat(log(seconds / (60.0 * M_E))) - 1.0) / 14.0;
					imageView.setImage(progressionImage(CGSizeMake(74.0, 74.0), progression: 0.5, color: UIColor.whiteColor(), radius: 14.0))
					
					timerLabel.setDate(endDate!)
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
		var path:CGPath = CGContextCopyPath(bitmapContext)
		
		CGContextSetLineCap(bitmapContext, kCGLineCapRound)
		CGContextSetLineWidth(bitmapContext, border * 2.0)
		CGContextSetStrokeColorWithColor(bitmapContext, color.colorWithAlphaComponent(0.5).CGColor)
		CGContextStrokePath(bitmapContext)
		
		let pathLength:CGFloat = (frame.height - 2.0 * border - 2.0 * cornerRadius) * 4.0 + 2.0 * CGFloat(M_PI) * cornerRadius
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
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
	
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
		
		update()
		timerLabel.start()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
		timerLabel.stop()
    }

}