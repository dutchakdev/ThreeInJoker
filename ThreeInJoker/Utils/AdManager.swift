//
//  AdManager.swift
//  ThreeInJoker
//
//  Created by Artyom Lihach on 29.12.2019.
//  Copyright © 2019 ThreeInJoker. All rights reserved.
//

import UIKit

class AdManager: NSObject {
	
	static let shared = AdManager()

	func jdprLink(agreements: String, params: String) -> String {
		var link = agreements
		
		if let appsflyerId = AdSettingsStorage.shared.appsflyerId {
			let appsflyerParams = "sub_id_10=\(appsflyerId)"
			link = self.append(param: appsflyerParams, to: link)
		}
		
		if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
			let identifierForVendorParam = "sub_id_7=\(identifierForVendor)"
			link = self.append(param: identifierForVendorParam, to: link)
		}
		
		link = self.append(param: params, to: link)
		return link
	}
	
	func append(param: String, to request: String) -> String {
		let concatSymbol: String
		if let query = URL(string: request)?.query {
			concatSymbol = query.count > 0 ? "&" : "?"
		} else {
			concatSymbol = "?"
		}
		
		return param.count > 0 ? request.appending("\(concatSymbol)\(param)") : request
	}
}
