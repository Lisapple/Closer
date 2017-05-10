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
	
	fileprivate var countdown: Countdown?
	
	override init() {
		super.init()
		
		let session = WCSession.default()
		session.delegate = self
		session.activate()
		
		let userDefaults = UserDefaults(suiteName: "group.lisacintosh.closer")!
		let glanceType = GlanceType(string: userDefaults.string(forKey: "glance_type"))
		countdown = Countdown.with(glanceType)
	}
	
	func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
		handler(.forward)
	}
	
	func templateForComplication(_ complication: CLKComplication, date: Date?) -> CLKComplicationTemplate? {
		let text = (self.countdown != nil) ? self.countdown!.shortRemainingDescription(forDate: date) : "--"
		let textProvider = CLKSimpleTextProvider(text: text, shortText: self.countdown?.shortestRemainingDescription(forDate: date))
		let progression: Float = (self.countdown != nil) ? Float(self.countdown!.progression(atDate: date)) : 0
		var template: CLKComplicationTemplate?
		
		switch complication.family {
			case .circularSmall:
				let aTemplate = CLKComplicationTemplateCircularSmallRingText()
				aTemplate.ringStyle = .closed
				aTemplate.fillFraction = progression
				aTemplate.textProvider = textProvider
				template = aTemplate
				break
			case .modularSmall:
				let aTemplate = CLKComplicationTemplateModularSmallRingText()
				aTemplate.ringStyle = .closed
				aTemplate.fillFraction = progression
				aTemplate.textProvider = textProvider
				template = aTemplate
				break
			case .modularLarge: break // @TODO: Support it
			case .utilitarianSmall:
				let aTemplate = CLKComplicationTemplateUtilitarianSmallRingText()
				aTemplate.ringStyle = .closed
				aTemplate.fillFraction = progression
				aTemplate.textProvider = textProvider
				template = aTemplate
				break
			case .utilitarianLarge, .extraLarge, .utilitarianSmallFlat: break // Not supported now
		}
		return template
	}
	
	func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
		if let template = templateForComplication(complication, date: nil) {
			let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
			handler(entry)
		} else {
			handler(nil)
		}
	}
	
	func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
		handler(Date())
	}
	
	func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
		handler(countdown?.endDate as Date?)
	}
	
	func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int,
	                        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
		handler(nil)
	}
	
	func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int,
	                        withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
		if (countdown?.endDate != nil) {
			var timeInterval: TimeInterval = 0
			var entries = [CLKComplicationTimelineEntry]()
			for _ in 0 ..< limit {
				let nextDate = Date(timeIntervalSinceNow: timeInterval)
				if (nextDate.timeIntervalSince(countdown!.endDate!) >= 0) {
					break
				}
				let template = templateForComplication(complication, date: nextDate)
				let entry = CLKComplicationTimelineEntry(date: nextDate, complicationTemplate: template!)
				timeInterval += countdown!.timeIntervalForNextUpdate(forDate: nextDate)
				entries.append(entry)
			}
			handler(entries)
		} else {
			handler(nil)
		}
	}
	
	func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
		let template = templateForComplication(complication, date: nil)
		handler(template)
	}
	
	@available(watchOSApplicationExtension 2.2, *)
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
}
