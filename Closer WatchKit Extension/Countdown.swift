//
//  Countdown.swift
//  Closer
//
//  Created by Max on 26/09/15.
//
//

import UIKit
import WatchConnectivity
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
	switch (lhs, rhs) {
		case let (l?, r?):
			return l < r
		case (nil, _?):
			return true
		default:
			return false
	}
}


enum CountdownType: UInt {
	case countdown
	case timer
}

enum GlanceType: UInt {
	case lastSelectedPage
	case closestCountdown
	case closestTimer
	
	init(string: String?) {
		if let string = string {
			switch string {
				case "closest_countdown":
					self.init(rawValue: GlanceType.closestCountdown.rawValue)!
				case "closest_timer":
					self.init(rawValue: GlanceType.closestTimer.rawValue)!
				default:
					self.init(rawValue: GlanceType.lastSelectedPage.rawValue)!
			}
		} else {
			self.init(rawValue: GlanceType.lastSelectedPage.rawValue)!
		}
	}
}

class Countdown: NSObject {
	
	var identifier: String {
		get { return _identifier }
	}
	fileprivate var _identifier: String
	var type: CountdownType = .countdown
	var style: ColorStyle = .day
	var name: String
	var endDate: Date?
	var message: String?
	var durations: [TimeInterval]?
	var names: [String]?
	var durationIndex: Int?
	var currentDuration: TimeInterval? {
		get {
			if let durations = durations, let durationIndex = durationIndex {
				return durations[durationIndex]
			}
			return nil
		}
	}
	var currentName: String? {
		get {
			if let names = names, let durationIndex = durationIndex {
				return names[durationIndex]
			}
			return nil
		}
	}
	
	class func allCountdowns() -> [Countdown] {
		let context = WCSession.default().receivedApplicationContext
		if let array = context["countdowns"] as? [[String : AnyObject]] {
			return array.map { Countdown(dictionary: $0) }
		}
		return [Countdown]()
	}
	
	class func countdownWith(_ identifier: String) -> Countdown? {
		return allCountdowns().filter { $0.identifier == identifier }.first
	}
	
	class func countdownWith(_ glanceType: GlanceType) -> Countdown? {
		var countdown: Countdown?
		let countdowns = allCountdowns()
		if (glanceType == .closestCountdown) {
			// Get all countdowns sorted by endDate
			var sortedCountdowns = countdowns.filter { $0.type == .countdown }
			sortedCountdowns.sort(by: { (countdown1: Countdown, countdown2: Countdown) -> Bool in
				if let endDate2 = countdown2.endDate {
					return (countdown1.endDate?.timeIntervalSince(endDate2) < 0) // Return true if endDate1 < endDate2 (i.e. endDate1 - endDate2 < 0)
				}
				return false
			})
			// Set |countdown| with the closest countdown to finish (if any)
			if (sortedCountdowns.first != nil && sortedCountdowns.first?.endDate != nil) {
				countdown = sortedCountdowns.first!
			}
		}
		else if (glanceType == .closestCountdown) {
			// Get all timers sorted by endDate
			var sortedTimers = countdowns.filter { $0.type == .timer }
			sortedTimers.sort(by: { (timer1: Countdown, timer2: Countdown) -> Bool in
				if let endDate2 = timer2.endDate {
					return (timer1.endDate?.timeIntervalSince(endDate2) < 0) // Return true if endDate1 < endDate2 (i.e. endDate1 - endDate2 < 0)
				}
				return false
			})
			// Set |countdown| with the closest timer to finish (if any, find the timer with the shortest duration else)
			if let firstSortedTimers = sortedTimers.first {
				if (firstSortedTimers.endDate != nil) {
					countdown = firstSortedTimers
				} else {
					sortedTimers.sort(by: { (timer1: Countdown, timer2: Countdown) -> Bool in
						let currentDuration1 = timer1.durations![timer1.durationIndex!]
						let currentDuration2 = timer2.durations![timer2.durationIndex!]
						return (currentDuration1 < currentDuration2) // asc order
					})
					if let firstSortedTimers = sortedTimers.first {
						countdown = firstSortedTimers
					}
				}
			}
		}
		if (glanceType == .lastSelectedPage || countdown == nil) {
			let identifier = UserDefaults().string(forKey: "selectedIdentifier")
			countdown = countdowns.filter { $0.identifier == identifier }.first ?? countdowns.first
		}
		return countdown
	}
	
	convenience init(dictionary: [String : AnyObject]) {
		var type = CountdownType(rawValue: 0)
		if let rawType = dictionary["type"] as? UInt {
			type = CountdownType(rawValue: rawType)!
		}
		
		var style = ColorStyle(rawValue: 0)
		if let rawStyle = dictionary["style"] as? UInt {
			style = ColorStyle(rawValue: rawStyle)!
		}
		self.init(name: dictionary["name"] as? String,
		          identifier: dictionary["identifier"] as? String,
		          type: type, style: style )
		
		if let endDate = dictionary["endDate"] as? String {
			let formatter = DateFormatter()
			formatter.timeStyle = .medium
			formatter.dateStyle = .medium
			self.endDate = formatter.date(from: endDate)
		}
		self.message = dictionary["message"] as? String
		self.durations = dictionary["durations"] as? [TimeInterval]
		self.durationIndex = dictionary["durationIndex"] as? Int
		self.names = dictionary["names"] as? [String]
	}
	
	init(name: String?, identifier: String?, type: CountdownType?, style: ColorStyle?) {
		self.name = (name != nil) ? name! : ((type != nil && type! == .timer) ? "New timer" : "New countdown")
		_identifier = identifier ?? UUID().uuidString
		super.init()
		
		if (type != nil) { self.type = type! }
		if (style != nil) { self.style = style! }
	}
	
	func toDictionary() -> [String : Any] {
		var dictionary: [String : Any] = [ "name" : name, "type" : type.rawValue, "style" : style.rawValue ]
		if let message = message {
			dictionary["message"] = message }
		if let endDate = endDate {
			let formatter = DateFormatter()
			formatter.timeStyle = .medium
			formatter.dateStyle = .medium
			dictionary["endDate"] = formatter.string(from: endDate)
		}
		if let durations = durations {
			dictionary["durations"] = durations }
		if let names = names {
			dictionary["names"] = names }
		if let durationIndex = durationIndex {
			dictionary["durationIndex"] = durationIndex }
		return dictionary
	}
}

extension Countdown {
	
	func progression(atDate date: Date?) -> Double {
		var progression: Double = 0
		if (self.type == .timer) { // Timer
			if let durations = self.durations, let durationIndex = self.durationIndex, durations.count > 0 {
				let duration = durations[durationIndex]
				let endDate = (date != nil) ? self.endDate!.addingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate
				let remaining = (endDate != nil) ? Date().timeIntervalSince(endDate!) : 0
				progression = 1 - (endDate?.timeIntervalSinceNow ?? remaining) / duration
			}
		} else { // Countdown
			if let endDate = (date != nil) ? self.endDate!.addingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate {
				let seconds = max(floor(endDate.timeIntervalSinceNow), 0) as Double
				progression = 1 - (log(seconds / (60 * M_E)) - 1) / 14;
			}
		}
		return progression
	}
	
	func progressionImageWithSize(_ size: CGSize, cornerRadius: CGFloat) -> UIImage { // Countdown: corner radius = 14, Timer = 74/2
		
		let progress = progression(atDate: nil)
		
		let frame = CGRect(origin: CGPoint.zero, size: size)
		UIGraphicsBeginImageContextWithOptions(frame.size, false /* non-opaque */, 0)
		
		let bitmapContext = UIGraphicsGetCurrentContext()!
		let border: CGFloat = 2
		let center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
		
		/* pt1 --- pt2 */
		/*  |       |  */
		/* pt3 --- pt4 */
		
		if (cornerRadius >= size.height / 2) { // Timer
			bitmapContext.addArc(center: center, radius: size.height / 2.0 - border,
			                     startAngle: -0.98 * .pi / 2, endAngle: 0.99 * 2 * .pi - .pi / 2,
			                     clockwise: false)
		} else { // Countdown
			let pt1 = CGPoint(x: cornerRadius + border, y: border)
			let pt2 = CGPoint(x: frame.width - cornerRadius - border, y: border)
			let pt3 = CGPoint(x: cornerRadius + border, y: frame.height - border)
			let pt4 = CGPoint(x: frame.width - cornerRadius - border, y: frame.height - border)
			
			bitmapContext.move(to: CGPoint(x: center.x + border * 2.0, y: pt1.y))
			bitmapContext.addLine(to: CGPoint(x: pt2.x, y: pt2.y))
			bitmapContext.addArc(tangent1End: CGPoint(x: pt2.x + cornerRadius, y: pt2.y),
			                     tangent2End: CGPoint(x: pt4.x + cornerRadius, y: pt4.y), radius: cornerRadius)
			bitmapContext.addArc(tangent1End: CGPoint(x: pt4.x + cornerRadius, y: pt4.y), tangent2End: pt4, radius: cornerRadius)
			bitmapContext.addLine(to: CGPoint(x: pt3.x, y: pt3.y))
			bitmapContext.addArc(tangent1End: CGPoint(x: pt3.x - cornerRadius, y: pt3.y),
			                     tangent2End: CGPoint(x: pt1.x - cornerRadius, y: pt1.y), radius: cornerRadius)
			bitmapContext.addArc(tangent1End: CGPoint(x: pt1.x - cornerRadius, y: pt1.y), tangent2End: pt1, radius: cornerRadius)
			bitmapContext.addLine(to: CGPoint(x: center.x - border * 2.0, y: pt1.y))
		}
		let path = bitmapContext.path!
		
		bitmapContext.setLineCap(.round)
		bitmapContext.setLineWidth(border * 2.0)
		let color = UIColor(colorStyle: self.style)
		bitmapContext.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
		bitmapContext.strokePath()
		
		if (cornerRadius >= size.height / 2.0) { // Timer
			// @TODO: Clip progression minimum to get progress bar start
			bitmapContext.addArc(center: center, radius: size.height / 2.0 - border,
			                     startAngle: -0.98 * .pi / 2,
			                     endAngle: 2 * .pi * CGFloat(progress * 0.98 + 0.01) - .pi / 2,
			                     clockwise: false)
			
			let path = bitmapContext.path!
			bitmapContext.setLineCap(.round)
			bitmapContext.setLineWidth(border * 4.0)
			bitmapContext.setStrokeColor(UIColor.black.cgColor)
			bitmapContext.strokePath()
			
			bitmapContext.addPath(path)
			bitmapContext.setLineCap(.round)
			bitmapContext.setLineWidth(border * 2.0)
			bitmapContext.setStrokeColor(color.cgColor)
			bitmapContext.strokePath()
		} else {
			let pathLength = (frame.height - 2.0 * border - 2.0 * cornerRadius) * 4.0 + 2.0 * CGFloat.pi * cornerRadius
			var lengths = [ CGFloat(progress) * pathLength, CGFloat.greatestFiniteMagnitude ]
			var transform = CGAffineTransform.identity
			let dashingPath = CGPath(__byDashing: path, transform: &transform, phase: 0.0, lengths: &lengths, count: Int(lengths.count))
			
			bitmapContext.beginPath()
			bitmapContext.addPath(dashingPath!)
			bitmapContext.setLineCap(.round)
			bitmapContext.setLineWidth(border * 4.0)
			bitmapContext.setStrokeColor(UIColor.black.cgColor)
			bitmapContext.strokePath()
			
			bitmapContext.beginPath()
			bitmapContext.addPath(dashingPath!)
			bitmapContext.setLineCap(.round)
			bitmapContext.setLineWidth(border * 2.0)
			bitmapContext.setStrokeColor(color.cgColor)
			bitmapContext.strokePath()
		}
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image!
	}
	
	func shortRemainingDescriptionAtDate(_ date: Date?) -> String {
		if let endDate = (date != nil) ? self.endDate!.addingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate {
			let days = endDate.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return "\(Int(days))d" }
			
			let hours = endDate.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return "\(Int(hours))h" }
			
			let minutes = endDate.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return "\(Int(minutes))m" }
			return "\(Int(endDate.timeIntervalSinceNow))s"
		}
		return "--"
	}
	
	func shortestRemainingDescriptionAtDate(_ date: Date?) -> String {
		if let endDate = (date != nil) ? self.endDate!.addingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate {
			let days = endDate.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return "\(Int(days))" }
			
			let hours = endDate.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return "\(Int(hours))" }
			
			let minutes = endDate.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return "\(Int(minutes))" }
			return "\(Int(endDate.timeIntervalSinceNow))"
		}
		return "--"
	}
	
	func timeIntervalForNextUpdateAtDate(_ date: Date?) -> TimeInterval {
		if let endDate = (date != nil) ? self.endDate!.addingTimeInterval(-date!.timeIntervalSinceNow) : self.endDate {
			let days = endDate.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return endDate.timeIntervalSinceNow - floor(days) * (24 * 60 * 60) }
			
			let hours = endDate.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return endDate.timeIntervalSinceNow - floor(hours) * (60 * 60) }
			
			let minutes = endDate.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return endDate.timeIntervalSinceNow - floor(minutes) * (60 * 60) }
			return 1
		}
		return 0
	}
}
