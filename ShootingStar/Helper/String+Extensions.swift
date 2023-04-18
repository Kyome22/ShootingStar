/*
  String+Extensions.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    var infoString: String {
        guard let str = Bundle.main.object(forInfoDictionaryKey: self) as? String else {
            fatalError("infoString key is not found.")
        }
        return str
    }
}
