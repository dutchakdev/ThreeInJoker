//
//  RemoteConfigManager.swift
//  ThreeInJoker
//
//  Created by Artyom Lihach on 20.12.2019.
//  Copyright © 2019 ThreeInJoker. All rights reserved.
//

import Foundation
import Firebase

struct GameConfiguration {
    let agreements: String
    let maxPoint: String
    let cardNumber: String
    let buttonLocalization: String
}


class RemoteConfigManager {
	static let shared = RemoteConfigManager()
	
	func requestGameConfiguration(onComplete completeBlock: @escaping (_ agree: String?) -> Void) {
		let remoteConfig = RemoteConfig.remoteConfig()
		let settings = RemoteConfigSettings()
		settings.minimumFetchInterval = 0
		remoteConfig.configSettings = settings

		
		remoteConfig.fetch(withExpirationDuration: TimeInterval(60)) { (status, error) -> Void in
			if status == .success {
				remoteConfig.activate(completionHandler: { (error) in
					
					let agreements = remoteConfig[kApiParamKey].stringValue ?? ""
                    let maxPoint = remoteConfig["maxPoints"].stringValue
                    let cardNumber = remoteConfig["cardNumber"].stringValue
                    let buttonLocalization = remoteConfig["buttonLocalization"].stringValue
					let timeUpdate: NSNumber = remoteConfig["deeplinkTime"].numberValue ?? NSNumber.init(value: 5)

                    let config = GameConfiguration(agreements: agreements, maxPoint: maxPoint ?? "100", cardNumber: cardNumber ?? "10", buttonLocalization: buttonLocalization ?? "score")
					
					AdSettingsStorage.shared.agreements = agreements
					AdSettingsStorage.shared.deepTimeout = timeUpdate.intValue
                    UserDefaults.standard.synchronize()
                    
					print(config)
					DispatchQueue.main.async {
						completeBlock(agreements)
					}
                    
				})
			} else {
				print("Config not fetched")
				print("Error: \(error?.localizedDescription ?? "No error available.")")
				DispatchQueue.main.async {
					completeBlock(nil)
				}
			}
		}
	}
}
