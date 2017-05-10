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
	case countdown
	case timer
}

enum GlanceType: UInt {
	/// Last selected countdonw or timer.
	case lastSelectedPage
	
	/// Nearest countdown to end.
	case closestCountdown
	
	/// Nearest timer to end.
	case closestTimer
	
	init(string: String?) {
		self = .lastSelectedPage
		
		if let string = string {
			switch string {
				case "closest_countdown":
					self = .closestCountdown
				case "closest_timer":
					self = .closestTimer
				default: break
			}
		}
	}
}

class Countdown: NSObject {
	
	var identifier: String {
		return _identifier
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
		if let durations = durations, let durationIndex = durationIndex {
			return durations[durationIndex]
		}
		return nil
		
	}
	var currentName: String? {
		if let names = names, let durationIndex = durationIndex {
			return names[durationIndex]
		}
		return nil
	}
	
	private var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.timeStyle = .medium
		formatter.dateStyle = .medium
		return formatter
	}
	
	static var all: [Countdown] {
		let context = WCSession.default().receivedApplicationContext
		if let array = context["countdowns"] as? [[String : AnyObject]] {
			return array.map { Countdown(dictionary: $0) }
		}
		return [Countdown]()
	}
	
	class func with(_ identifier: String) -> Countdown? {
		return all.filter { $0.identifier == identifier }.first
	}
	
	class func with(_ glanceType: GlanceType) -> Countdown? {
		var countdown: Countdown?
		if (glanceType == .closestCountdown) { // Nearest to end
			let countdowns = all.filter { $0.type == .countdown && $0.endDate != nil }
			countdown = countdowns.sorted {
				$0.endDate!.timeIntervalSince($1.endDate!) < 0 }.first
		}
		else if (glanceType == .closestTimer) { // Closest timer to end or timer with the shortest duration
			let timers = all.filter { $0.type == .timer }
			let nonFinishedTimers = timers.filter {
				$0.endDate != nil
			}.sorted {
				$0.endDate!.timeIntervalSince($1.endDate!) < 0
			}
			countdown = nonFinishedTimers.first ?? timers.sorted { return ($0.currentDuration! < $1.currentDuration!) }.first
		}
		if (glanceType == .lastSelectedPage || countdown == nil) {
			let identifier = UserDefaults().string(forKey: "selectedIdentifier")
			countdown = .with(identifier ?? "") ?? all.first
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
			self.endDate = dateFormatter.date(from: endDate)
		}
		self.message = dictionary["message"] as? String
		self.durations = dictionary["durations"] as? [TimeInterval]
		self.durationIndex = dictionary["durationIndex"] as? Int
		self.names = dictionary["names"] as? [String]
	}
	
	init(name: String?, identifier: String?, type: CountdownType?, style: ColorStyle?) {
		self.name = name ?? NSLocalizedString((type == .timer) ? "new.timer.name" : "new.countdown.name", comment: "")
		_identifier = identifier ?? UUID().uuidString
		super.init()
		
		if let type = type { self.type = type }
		if let style = style { self.style = style }
	}
	
	func toDictionary() -> [String : Any] {
		var dictionary: [String : Any] = [ "name" : name, "type" : type.rawValue, "style" : style.rawValue ]
		if let message = message {
			dictionary["message"] = message }
		if let endDate = endDate {
			dictionary["endDate"] = dateFormatter.string(from: endDate) }
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
				let endDate = self.endDate?.addingTimeInterval(-(date?.timeIntervalSinceNow ?? 0))
				progression = 1 - (endDate?.timeIntervalSinceNow ?? 0) / duration
			}
		} else { // Countdown
			let endDate = self.endDate!.addingTimeInterval(-(date?.timeIntervalSinceNow ?? 0))
			let seconds = max(floor(endDate.timeIntervalSinceNow), 0)
			progression = 1 - (log(seconds / (60 * M_E)) - 1) / 14;
		}
		return progression
	}
	
	func progressionImage(size: CGSize, cornerRadius: CGFloat) -> UIImage { // Countdown: corner radius = 14, Timer = 74/2
		
		let progress = progression(atDate: nil)
		
		let frame = CGRect(origin: .zero, size: size)
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
	
	func shortRemainingDescription(forDate date: Date?) -> String {
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
	
	func shortestRemainingDescription(forDate date: Date?) -> String {
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
	
	func timeIntervalForNextUpdate(forDate date: Date?) -> TimeInterval {
		if let endDate = self.endDate?.addingTimeInterval(-(date?.timeIntervalSinceNow ?? 0)) {
			let days = endDate.timeIntervalSinceNow / (24 * 60 * 60)
			if (days >= 2) {
				return endDate.timeIntervalSinceNow - floor(days) * (24 * 60 * 60)
			}
			let hours = endDate.timeIntervalSinceNow / (60 * 60)
			if (hours >= 2) {
				return endDate.timeIntervalSinceNow - floor(hours) * (60 * 60)
			}
			let minutes = endDate.timeIntervalSinceNow / 60
			if (minutes >= 2) {
				return endDate.timeIntervalSinceNow - floor(minutes) * (60 * 60)
			}
			return 1
		}
		return 0
	}
}
