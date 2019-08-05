//
//  ColorX.swift
//  ABGAugeViewV2
//
//  Created by Ajay Bhanushali on 19/07/18.
//  Copyright © 2018 Aimpact. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha:1)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        let scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        
        var hexInt:UInt32 = 0x0
        scanner.scanHexInt32(&hexInt)

        let red = CGFloat((hexInt & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexInt & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexInt & 0xff) >> 0) / 255.0
        
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
