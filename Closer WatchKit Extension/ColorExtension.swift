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
	case day
	case dawn
	case oasis
	case spring
	case night
	
	static var styles: [ColorStyle] {
		return [.day, .dawn, .oasis, .spring, .night]
	}
	
	var name: String {
		switch self {
			case .day:	  return LocalizedString("style.day.name")
			case .dawn:	  return LocalizedString("style.dawn.name")
			case .oasis:  return LocalizedString("style.oasis.name")
			case .spring: return LocalizedString("style.spring.name")
			case .night:  return LocalizedString("style.night.name")
		}
	}
}

extension UIColor {
	
	convenience init(colorStyle:ColorStyle) {
		switch colorStyle {
			case .day:	  self.init(red: 74/255,  green: 74/255,  blue: 74/255,  alpha: 1)
			case .dawn:	  self.init(red: 90/255,  green: 170/255, blue: 240/255, alpha: 1)
			case .oasis:  self.init(red: 105/255, green: 198/255, blue: 13/255,  alpha: 1)
			case .spring: self.init(red: 0/255,   green: 39/255,  blue: 153/255, alpha: 1)
			case .night:  self.init(white: 1, alpha:1)
		}
	}
}
