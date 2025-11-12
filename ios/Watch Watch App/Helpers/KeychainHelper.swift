//
//  KeychainHelper.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation
import Security

class KeychainHelper {
    static func getSynjonesAuth() -> String? {
        #if DEBUG
        let accessGroup = "group.top.celechron.celechron.debug"
        #else
        let accessGroup = "group.top.celechron.celechron"
        #endif
        
        let keychainQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccount: "synjonesAuth",
            kSecAttrAccessGroup: accessGroup,
            kSecAttrService: "Celechron",
            kSecAttrSynchronizable: false,
            kSecReturnData: true,
        ]
        
        var ref: AnyObject?
        let status = SecItemCopyMatching(
            keychainQuery as CFDictionary,
            &ref
        )
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status == noErr {
            if let data = ref as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        
        return nil
    }
}

