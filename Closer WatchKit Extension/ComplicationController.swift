//
//  ComplicationDataSourceController.swift
//  Closer
//
//  Created by Max on 02/10/15.
//
//

import ClockKit
import WatchConnectivity

class ComplicationController: NSObject, CLKComplicationDataSource, WCSessionDelegate {
	
	private var countdown: Countdown?
	
	override init() {
		super.init()
		
		let session = WCSession.defaultSession()
		session.delegate = self
		session.activateSession()
		
		let userDefaults = NSUserDefaults(suiteName: "group.lisacintosh.closer")!
		let glanceType = GlanceType(string: userDefaults.stringForKey("glance_type"))
		countdown = Countdown.countdownWith(glanceType)
	}
	
	func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
		handler(.Forward)
	}
	
	func templateForComplication(complication: CLKComplication, date: NSDate?) -> CLKComplicationTemplate? {
		let text = (self.countdown != nil) ? self.countdown!.shortRemainingDescriptionAtDate(date) : "--"
		let textProvider = CLKSimpleTextProvider(text: text, shortText: self.countdown?.shortestRemainingDescriptionAtDate(date))
		let progression = (self.countdown != nil) ? Float(self.countdown!.progressionAtDate(date)) : Float(0)
		var template: CLKComplicationTemplate?
		
		switch complication.family {
		case .CircularSmall:
			let aTemplate = CLKComplicationTemplateCircularSmallRingText()
			aTemplate.ringStyle = .Closed
			aTemplate.fillFraction = progression
			aTemplate.textProvider = textProvider
			template = aTemplate
			break
		case .ModularSmall:
			let aTemplate = CLKComplicationTemplateModularSmallRingText()
			aTemplate.ringStyle = .Closed
			aTemplate.fillFraction = progression
			aTemplate.textProvider = textProvider
			template = aTemplate
			break
		case .ModularLarge: break // @TODO: Support it
		case .UtilitarianSmall:
			let aTemplate = CLKComplicationTemplateUtilitarianSmallRingText()
			aTemplate.ringStyle = .Closed
			aTemplate.fillFraction = progression
			aTemplate.textProvider = textProvider
			template = aTemplate
			break
		case .UtilitarianLarge: break // Not supported now
		}
		return template
	}
	
	func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimelineEntry?) -> Void) {
		
		let template = templateForComplication(complication, date: nil)
		if (template != nil) {
			let entry = CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template!)
			handler(entry)
		} else {
			handler(nil)
		}
	}
	
	func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
		handler(NSDate())
	}
	
	func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
		handler(countdown?.endDate)
	}
	
	func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
		print("beforeDate: ", date, limit)
		handler(nil)
	}
	
	func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
		if (countdown?.endDate != nil) {
			var timeInterval: NSTimeInterval = 0
			var entries = [CLKComplicationTimelineEntry]()
			for _ in 0 ..< limit {
				let nextDate = NSDate(timeIntervalSinceNow: timeInterval)
				if (nextDate.timeIntervalSinceDate(countdown!.endDate!) >= 0) {
					break
				}
				let template = templateForComplication(complication, date: nextDate)
				let entry = CLKComplicationTimelineEntry(date: nextDate, complicationTemplate: template!)
				timeInterval += countdown!.timeIntervalForNextUpdateAtDate(nextDate)
				entries.append(entry)
			}
			//print(entries.map { (entry: CLKComplicationTimelineEntry) -> String in
			//	return ((entry.complicationTemplate as! CLKComplicationTemplateUtilitarianSmallRingText).textProvider as! CLKSimpleTextProvider).text })
			handler(entries)
		} else {
			handler(nil)
		}
	}
	
	func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
		let template = templateForComplication(complication, date: nil)
		handler(template)
	}
}
