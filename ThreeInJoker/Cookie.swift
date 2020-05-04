//
//  Cookie.swift
//  BiscuitCrunch
//
//  Created by Leonardo Almeida silva ferreira on 24/09/16.
//  Copyright © 2016 kkwFwk. All rights reserved.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible {
    case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie
    
    var spriteName: String {
        let spriteNames = [
            "apple_icon",
            "banana_icon",
            "cherry_icon",
            "lemon_icon",
            "pear_icon",
            "joker_icon"]
        
        return spriteNames[rawValue - 1] + "_shad"
    }
    
    var highlightedSpriteName: String {
		return spriteName.replacingOccurrences(of: "_shad", with: "")
    }
    
    var description: String {
        return spriteName
    }
    
    static func random() -> CookieType {
        return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    
}

class Cookie: CustomStringConvertible, Hashable {

    var column: Int
    var row: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    
    var description: String {
        return "type:\(cookieType) square:(\(column),\(row))"
    }
    
    var hashValue: Int {
        return row*10 + column
    }
    
    init(column: Int, row: Int, cookieType: CookieType){
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
    
}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}
