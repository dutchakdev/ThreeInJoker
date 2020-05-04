//
//  GameStorage.swift


import UIKit

class AdSettingsStorage: NSObject {
	
	let appsFlayerDevKey = "BDREFvBLEZQKVYEhZafc85"
	
	private let kDeeplinkTimeout: Int = 5
	private let kSettingUserAccount = "kSettingUserAccount"
	private let kSettingUserId = "kSettingUserId"
	private let kSettingAgreements = "kSettingAgreements"
	private let kSettingParams = "kSettingParams"
	private let kSettingPushToken = "kSettingPushToken"
	private let kSettingDeeplinkTimeout = "kSettingDeeplinkTimeout"
	private let kSettingAppsflayerUserId = "kSettingAppsflayerUserId"
	
	static let shared = AdSettingsStorage()
	
	var agreements: String? {
		set {
			UserDefaults.standard.set(newValue, forKey: kSettingAgreements)
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.string(forKey: kSettingAgreements)
		}
	}
	
	var deepParams: String? {
		set {
			UserDefaults.standard.set(newValue, forKey: kSettingParams)
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.string(forKey: kSettingParams)
		}
	}
	
	var deepTimeout: Int {
		set {
			UserDefaults.standard.set(newValue, forKey: kSettingDeeplinkTimeout)
			UserDefaults.standard.synchronize()
		}
		get {
			let timeout = UserDefaults.standard.integer(forKey: kSettingDeeplinkTimeout)
			return timeout > 0 ? timeout : kDeeplinkTimeout
		}
	}
	
	var userId: String? {
		set {
			if let newValue = newValue {
				Keychain.setPassword(newValue, forAccount: kSettingUserAccount)
			}
		}
		get {
			return Keychain.password(forAccount: kSettingUserAccount)
		}
	}
	
	var appsflyerId: String? {
		set {
			UserDefaults.standard.set(newValue, forKey: kSettingAppsflayerUserId)
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.string(forKey: kSettingAppsflayerUserId)
		}
	}
	
	var pushToken: String? {
		set {
			UserDefaults.standard.set(newValue, forKey: kSettingPushToken)
			UserDefaults.standard.synchronize()
		}
		get {
			return UserDefaults.standard.string(forKey: kSettingPushToken)
		}
	}
	
	
}
