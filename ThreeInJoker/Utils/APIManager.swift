//
//  Copyright © 2018. All rights reserved.

import UIKit
import Alamofire

@objc class APIManager: NSObject {
    static let shared = APIManager()
    
	func sendPushToken(_ deviceToken: String, onComplete completeBlock: @escaping () -> Void) {
        
		var params = [String : String]()
		if let bundleIdentifier = Bundle.main.bundleIdentifier {
			params["appBundle"] = bundleIdentifier
		}
		if let bundleIdentifier = Bundle.main.bundleIdentifier {
			params["appBundle"] = bundleIdentifier
		}
		if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
			params["deviceId"] = identifierForVendor
		}
		if let langStr = Locale.current.languageCode {
			params["locale"] = langStr
		}
		params["deviceToken"] = deviceToken
		
		Alamofire.request("https://sevas.site/loguser", method: .post, parameters: nil, encoding: URLEncoding.default, headers: ["Content-Type" : "application/json"]).responseString(completionHandler: { response in
			if response.result.isSuccess {
				completeBlock()
			} else {
				completeBlock()
			}
        })
    }
    
}

