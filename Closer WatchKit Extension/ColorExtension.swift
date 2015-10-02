//
//  ColorExtension.swift
//  TestWatch
//
//  Created by Max on 15/03/15.
//  Copyright (c) 2015 lis@cintosh. All rights reserved.
//

import Foundation
import UIKit

enum ColorStyle: UInt {
	case Day
	case Dawn
	case Oasis
	case Spring
	case Night
	case NumberOfStyle
	
	static func fromString(str: String) -> ColorStyle {
		switch str {
			case "day":		return .Day
			case "dawn":	return .Dawn
			case "oasis":	return .Oasis
			case "spring":	return .Spring
			default:		return .Night
		}
	}
	
	func toString() -> String? {
		switch self {
			case .Day:		return "day"
			case .Dawn:		return "dawn"
			case .Oasis:	return "oasis"
			case .Spring:	return "spring"
			case .Night:	return "night"
			default: return nil
		}
	}
}

extension UIColor {
	convenience init(colorStyle:ColorStyle) {
		switch colorStyle {
			case .Day:		self.init(red: 74/255,  green: 74/255,  blue: 74/255,  alpha: 1)
			case .Dawn:		self.init(red: 85/255,  green: 175/255, blue: 255/255, alpha: 1)
			case .Oasis:	self.init(red: 126/255, green: 211/255, blue: 33/255,  alpha: 1)
			case .Spring:	self.init(red: 6/255,   green: 20/255,  blue: 158/255, alpha: 1)
			case .Night:	self.init(white: 1, alpha:1)
			default:		self.init(white: 0, alpha:0)
		}
	}
}