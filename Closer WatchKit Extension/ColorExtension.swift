//
//  ColorExtension.swift
//  TestWatch
//
//  Created by Max on 15/03/15.
//  Copyright (c) 2015 lis@cintosh. All rights reserved.
//

import Foundation
import UIKit

enum ColorStyle : UInt {
	case ColorStyleDay
	case ColorStyleDawn
	case ColorStyleOasis
	case ColorStyleSpring
	case ColorStyleNight
	
	static func fromInt(index:Int) -> ColorStyle {
		return [.ColorStyleNight, .ColorStyleDay, .ColorStyleDawn, .ColorStyleOasis, .ColorStyleSpring][index]
	}
	
	static func fromString(str:String) -> ColorStyle {
		switch str {
			case "day":		return .ColorStyleDay
			case "dawn":	return .ColorStyleDawn
			case "oasis":	return .ColorStyleOasis
			case "spring":	return .ColorStyleSpring
			default:		return .ColorStyleNight
		}
	}
	
	func toString() -> String {
		switch self {
			case .ColorStyleDay:	return "day"
			case .ColorStyleDawn:	return "dawn"
			case .ColorStyleOasis:	return "oasis"
			case .ColorStyleSpring:	return "spring"
			case .ColorStyleNight:	return "night"
		}
	}
}

extension UIColor {
	convenience init(colorStyle:ColorStyle) {
		switch colorStyle {
			case .ColorStyleDay:	self.init(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
			case .ColorStyleDawn:	self.init(red: 85.0/255.0, green: 175.0/255.0, blue: 255.0/255.0, alpha: 1.0)
			case .ColorStyleOasis:	self.init(red: 126.0/255.0, green: 211.0/255.0, blue: 33.0/255.0, alpha: 1.0)
			case .ColorStyleSpring:	self.init(red: 6.0/255.0, green: 20.0/255.0, blue: 158.0/255.0, alpha: 1.0)
			case .ColorStyleNight:	self.init(white: 1.0, alpha:1.0)
		}
	}
}