//
//  Countdown.swift
//  Closer
//
//  Created by Max on 26/09/15.
//
//

import UIKit
import WatchConnectivity

enum CountdownType: UInt {
	case Countdown
	case Timer
}

enum GlanceType: UInt {
	case LastSelectedPage
	case ClosestCountdown
	case ClosestTimer
	
	init(string: String?) {
		if (string != nil) {
			switch string! {
			case "closest_countdown":
				self.init(rawValue: GlanceType.ClosestCountdown.rawValue)!
			case "closest_timer":
				self.init(rawValue: GlanceType.ClosestTimer.rawValue)!
			default:
				self.init(rawValue: GlanceType.LastSelectedPage.rawValue)!
			}
		} else {
			self.init(rawValue: GlanceType.LastSelectedPage.rawValue)!
		}
	}
}

class Countdown: NSObject {
	
	var identifier: String {
		get { return _identifier }
	}
	private var _identifier: String
	var type = CountdownType(rawValue: 0)!
	var style = ColorStyle(rawValue: 0)!
	var name: String
	var endDate: NSDate?
	var message: String?
	var durations: [NSTimeInterval]?
	var names: [String]?
	var durationIndex: Int?
	var currentDuration: NSTimeInterval? {
		get {
			if (durations != nil && durationIndex != nil) {
				return durations![durationIndex!] }
			return nil
		}
	}
	var currentName: String? {
		get {
			if (names != nil && durationIndex != nil) {
				return names![durationIndex!] }
			return nil
		}
	}
	
	class func allCountdowns() -> [Countdown] {
		let context = WCSession.defaultSession().receivedApplicationContext
		let array = context["countdowns"] as? [[String : AnyObject]]
		var countdowns = [Countdown]()
		if (array != nil) {
			for dict in array! {
				let countdown = Countdown(dictionary: dict)
				countdowns.append(countdown)
			}
		}
		return countdowns
	}
	
	class func countdownWithType(type: GlanceType) -> Countdown? {
		var countdown: Countdown?
		let countdowns = allCountdowns()
		if (type == .ClosestCountdown) {
			// Get all countdowns sorted by endDate
			var sortedCountdowns = countdowns.filter({ (countdown: Countdown) -> Bool in
				return (countdown.type == .Countdown) })
			sortedCountdowns.sortInPlace({ (countdown1: Countdown, countdown2: Countdown) -> Bool in
				if (countdown2.endDate != nil) {
					return (countdown1.endDate?.timeIntervalSinceDate(countdown2.endDate!) < 0) // Return true if endDate1 < endDate2 (i.e. endDate1 - endDate2 < 0)
				}
				return false
			})
			// Set |countdown| with the closest countdown to finish (if any)
			if (sortedCountdowns.first != nil && sortedCountdowns.first?.endDate != nil) {
				countdown = sortedCountdowns.first!
			}
		}
		else if (type == .ClosestCountdown) {
			// Get all timers sorted by endDate
			var sortedTimers = countdowns.filter({ (timer: Countdown) -> Bool in
				return (timer.type == .Timer) })
			sortedTimers.sortInPlace({ (timer1: Countdown, timer2: Countdown) -> Bool in
				if (timer2.endDate != nil) {
					return (timer1.endDate?.timeIntervalSinceDate(timer2.endDate!) < 0) // Return true if endDate1 < endDate2 (i.e. endDate1 - endDate2 < 0)
				}
				return false
			})
			// Set |countdown| with the closest timer to finish (if any, find the timer with the shortest duration else)
			if (sortedTimers.first != nil) {
				if (sortedTimers.first!.endDate != nil) {
					countdown = sortedTimers.first!
				} else {
					sortedTimers.sortInPlace({ (timer1: Countdown, timer2: Countdown) -> Bool in
						let currentDuration1 = timer1.durations![timer1.durationIndex!]
						let currentDuration2 = timer2.durations![timer2.durationIndex!]
						return (currentDuration1 < currentDuration2) // asc order
					})
					if (sortedTimers.first != nil) {
						countdown = sortedTimers.first!
					}
				}
			}
		}
		if (type == .LastSelectedPage || countdown == nil) {
			let identifier = NSUserDefaults().stringForKey("selectedIdentifier")
			countdown = countdowns.filter({ (countdown: Countdown) -> Bool in
				return (countdown.identifier == identifier) }).first
			if (countdown == nil) {
				countdown = countdowns.first
			}
		}
		return countdown
	}
	
	convenience init(dictionary: [String : AnyObject]) {
		var type = CountdownType(rawValue: 0)
		if (dictionary["type"] as? UInt != nil) {
			type = CountdownType(rawValue: dictionary["type"] as! UInt)!
		}
		
		var style = ColorStyle(rawValue: 0)
		if (dictionary["style"] as? UInt != nil) {
			style = ColorStyle(rawValue: dictionary["style"] as! UInt)!
		}
		self.init(
			name: dictionary["name"] as? String,
			identifier: dictionary["identifier"] as? String,
			type: type, style: style )
		
		if (dictionary["endDate"] is String) {
			let formatter = NSDateFormatter()
			formatter.timeStyle = .MediumStyle
			formatter.dateStyle = .MediumStyle
			self.endDate = formatter.dateFromString(dictionary["endDate"] as! String)
		}
		self.message = dictionary["message"] as? String
		self.durations = dictionary["durations"] as? [NSTimeInterval]
		self.names = dictionary["names"] as? [String]
	}
	
	init(name: String?, identifier: String?, type: CountdownType?, style: ColorStyle?) {
		self.name = (name != nil) ? name! : ((type != nil && type! == .Timer) ? "New timer" : "New countdown")
		if (identifier != nil) {
			_identifier = identifier!
		} else {
			let maximumIdentifier = Countdown.allCountdowns().maxElement({ (countdown1: Countdown, countdown2: Countdown) -> Bool in
				return (Int(countdown1.identifier) < Int(countdown2.identifier)) })?.identifier
			_identifier = (maximumIdentifier != nil) ? String(Int(maximumIdentifier!)! + 1) : String(1)
		}
		super.init()
		
		if (type != nil) { self.type = type! }
		if (style != nil) { self.style = style! }
	}
	
	func toDictionary() -> [String : AnyObject] {
		var dictionary: [String : AnyObject] = [ "name" : name, "type" : type.rawValue, "style" : style.rawValue ]
		if (message != nil) {
			dictionary["message"] = message! }
		if (endDate != nil) {
			let formatter = NSDateFormatter()
			formatter.timeStyle = .MediumStyle
			formatter.dateStyle = .MediumStyle
			dictionary["endDate"] = formatter.stringFromDate(endDate!) }
		if (durations != nil) {
			dictionary["durations"] = durations }
		if (names != nil) {
			dictionary["names"] = names }
		if (durationIndex != nil) {
			dictionary["durationIndex"] = durationIndex }
		return dictionary
	}
}

extension Countdown {
	
	func progressionAtDate(date: NSDate?) -> Double {
		var progression: Double = 0
		if (self.type == .Timer) { // Timer
			let index = self.durationIndex!
			let durations = self.durations!
			if (durations.count > 0) {
				let duration = durations[index]
				let endDate: NSDate? = (self.endDate != nil) ? ((date != nil) ? self.endDate!.dateByAddingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate!) : nil
				let remaining = (endDate != nil) ? NSDate().timeIntervalSinceDate(endDate!) : 0
				progression = 1 - ((endDate != nil) ? endDate!.timeIntervalSinceNow : remaining) / duration
			}
		} else { // Countdown
			let endDate: NSDate? = (self.endDate != nil) ? ((date != nil) ? self.endDate!.dateByAddingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate!) : nil
			if (endDate != nil) {
				let seconds = max(floor(endDate!.timeIntervalSinceNow), 0) as Double
				progression = 1 - (log(seconds / (60 * M_E)) - 1) / 14;
			}
		}
		return progression
	}
	
	func progressionImageWithSize(size: CGSize, cornerRadius: CGFloat) -> UIImage { // Countdown: corner radius = 14, Timer = 74/2
		
		let progress = progressionAtDate(nil)
		
		let frame: CGRect = CGRectMake(0, 0, size.width, size.width)
		UIGraphicsBeginImageContextWithOptions(frame.size, false /* non-opaque */, 0)
		
		let bitmapContext: CGContext = UIGraphicsGetCurrentContext()!
		let border: CGFloat = 2
		let center: CGPoint = CGPointMake(frame.size.width / 2, frame.size.height / 2)
		
		/*  pt1 --- pt2  */
		/*	 |       |   */
		/*  pt3 --- pt4  */
		
		if (cornerRadius >= size.height / 2) { // Timer
			CGContextAddArc(bitmapContext, center.x, center.y, size.height / 2.0 - border,
				CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * 0.99 - M_PI_2), 0)
		} else { // Countdown
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
		let path:CGPath = CGContextCopyPath(bitmapContext)!
		
		CGContextSetLineCap(bitmapContext, .Round)
		CGContextSetLineWidth(bitmapContext, border * 2.0)
		let color = UIColor(colorStyle: self.style)
		CGContextSetStrokeColorWithColor(bitmapContext, color.colorWithAlphaComponent(0.5).CGColor)
		CGContextStrokePath(bitmapContext)
		
		if (cornerRadius >= size.height / 2.0) { // Timer
			// @TODO: Clip progression minimum to get progress bar start
			CGContextAddArc(bitmapContext, center.x, center.y, size.height / 2.0 - border,
				CGFloat(-M_PI_2 * 0.98), CGFloat(2 * M_PI * (Double(progress) * 0.98 + 0.01) - M_PI_2), 0)
			
			let path:CGPathRef = CGContextCopyPath(bitmapContext)!
			CGContextSetLineCap(bitmapContext, .Round)
			CGContextSetLineWidth(bitmapContext, border * 4.0)
			CGContextSetStrokeColorWithColor(bitmapContext, UIColor.blackColor().CGColor)
			CGContextStrokePath(bitmapContext)
			
			CGContextAddPath(bitmapContext, path)
			CGContextSetLineCap(bitmapContext, .Round)
			CGContextSetLineWidth(bitmapContext, border * 2.0)
			CGContextSetStrokeColorWithColor(bitmapContext, color.CGColor)
			CGContextStrokePath(bitmapContext)
		} else {
			let pathLength = (frame.height - 2.0 * border - 2.0 * cornerRadius) * 4.0 + 2.0 * CGFloat(M_PI) * cornerRadius
			var lengths = [ CGFloat(progress) * pathLength, CGFloat.max ]
			var transform = CGAffineTransformIdentity
			let dashingPath = CGPathCreateCopyByDashingPath(path, &transform, 0.0, &lengths, Int(lengths.count))
			
			CGContextBeginPath(bitmapContext)
			CGContextAddPath(bitmapContext, dashingPath)
			CGContextSetLineCap(bitmapContext, .Round)
			CGContextSetLineWidth(bitmapContext, border * 4.0)
			CGContextSetStrokeColorWithColor(bitmapContext, UIColor.blackColor().CGColor)
			CGContextStrokePath(bitmapContext)
			
			CGContextBeginPath(bitmapContext)
			CGContextAddPath(bitmapContext, dashingPath)
			CGContextSetLineCap(bitmapContext, .Round)
			CGContextSetLineWidth(bitmapContext, border * 2.0)
			CGContextSetStrokeColorWithColor(bitmapContext, color.CGColor)
			CGContextStrokePath(bitmapContext)
		}
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
	
	func shortRemainingDescriptionAtDate(date: NSDate?) -> String {
		let endDate: NSDate? = (self.endDate != nil) ? ((date != nil) ? self.endDate!.dateByAddingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate!) : nil
		if (endDate != nil) {
			let days = endDate!.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return "\(Int(days))d" }
			
			let hours = endDate!.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return "\(Int(hours))h" }
			
			let minutes = endDate!.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return "\(Int(minutes))m" }
			return "\(Int(endDate!.timeIntervalSinceNow))s"
		}
		return "--"
	}
	
	func shortestRemainingDescriptionAtDate(date: NSDate?) -> String {
		let endDate: NSDate? = (self.endDate != nil) ? ((date != nil) ? self.endDate!.dateByAddingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate!) : nil
		if (endDate != nil) {
			let days = endDate!.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return "\(Int(days))" }
			
			let hours = endDate!.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return "\(Int(hours))" }
			
			let minutes = endDate!.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return "\(Int(minutes))" }
			return "\(Int(endDate!.timeIntervalSinceNow))"
		}
		return "--"
	}
	
	func timeIntervalForNextUpdateAtDate(date: NSDate?) -> NSTimeInterval {
		let endDate: NSDate? = (self.endDate != nil) ? ((date != nil) ? self.endDate!.dateByAddingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate!) : nil
		if (endDate != nil) {
			let days = endDate!.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return endDate!.timeIntervalSinceNow - floor(days) * (24 * 60 * 60) }
			
			let hours = endDate!.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return endDate!.timeIntervalSinceNow - floor(hours) * (60 * 60) }
			
			let minutes = endDate!.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return endDate!.timeIntervalSinceNow - floor(minutes) * (60 * 60) }
			return 1
		}
		return 0
	}
}
