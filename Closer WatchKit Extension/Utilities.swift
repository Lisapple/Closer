//
//  Utilities.swift
//  Closer
//
//  Created by Max on 11/05/2017.
//
//

import Foundation

func LocalizedString(_ key: String, comment: String? = nil) -> String {
	return NSLocalizedString(key, comment: comment ?? "")
}

func LocalizedFormat(_ format: Any ...) -> String {
	let arguments = [Any](format.dropFirst()).map { $0 as AnyObject as! CVarArg }
	return String(format: LocalizedString(format.first as! String),
	              arguments: arguments)
}
