//
//  KeychainHelper.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation
import Security
import os.log

class KeychainHelper {
    private static let logger = OSLog(subsystem: "top.celechron.celechron.watch", category: "KeychainHelper")
    
    static func getSynjonesAuth() -> String? {
        #if DEBUG
        let accessGroup = "group.top.celechron.celechron.debug"
        #else
        let accessGroup = "group.top.celechron.celechron"
        #endif
        
        os_log("🔑 [Keychain] 开始读取认证信息，AccessGroup: %{public}@", log: logger, type: .info, accessGroup)
        
        // 尝试多种查询方式，兼容flutter_secure_storage的存储格式
        
        // 方式1: 使用Service和Account（flutter_secure_storage的标准格式）
        var keychainQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "synjonesAuth",
            kSecAttrAccessGroup: accessGroup,
            kSecAttrService: "Celechron",
            kSecReturnData: true,
        ]
        
        var ref: AnyObject?
        var status = SecItemCopyMatching(keychainQuery as CFDictionary, &ref)
        
        os_log("🔑 [Keychain] 方式1返回状态码: %d", log: logger, type: .info, status)
        
        if status == noErr, let data = ref as? Data, let authString = String(data: data, encoding: .utf8) {
            os_log("✅ [Keychain] 方式1成功读取认证信息，长度: %d", log: logger, type: .info, authString.count)
            print("✅ [Keychain] 成功读取认证信息（方式1），前10个字符: \(authString.prefix(10))...")
            return authString
        }
        
        // 方式2: 只使用Account和AccessGroup（不指定Service）
        ref = nil
        keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "synjonesAuth",
            kSecAttrAccessGroup: accessGroup,
            kSecReturnData: true,
        ]
        
        status = SecItemCopyMatching(keychainQuery as CFDictionary, &ref)
        os_log("🔑 [Keychain] 方式2返回状态码: %d", log: logger, type: .info, status)
        
        if status == noErr, let data = ref as? Data, let authString = String(data: data, encoding: .utf8) {
            os_log("✅ [Keychain] 方式2成功读取认证信息，长度: %d", log: logger, type: .info, authString.count)
            print("✅ [Keychain] 成功读取认证信息（方式2），前10个字符: \(authString.prefix(10))...")
            return authString
        }
        
        // 方式3: 尝试列出所有同AccessGroup的Keychain项用于调试
        ref = nil
        keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessGroup: accessGroup,
            kSecReturnAttributes: true,
            kSecReturnData: false,
            kSecMatchLimit: kSecMatchLimitAll,
        ]
        
        var allItems: AnyObject?
        let listStatus = SecItemCopyMatching(keychainQuery as CFDictionary, &allItems)
        
        if listStatus == noErr, let items = allItems as? [[String: Any]] {
            os_log("📋 [Keychain] 找到 %d 个Keychain项", log: logger, type: .info, items.count)
            print("📋 [Keychain] 在AccessGroup中找到 \(items.count) 个Keychain项:")
            for (index, item) in items.enumerated() {
                if let account = item[kSecAttrAccount as String] as? String,
                   let service = item[kSecAttrService as String] as? String {
                    print("  [\(index + 1)] Account: \(account), Service: \(service)")
                }
            }
        } else {
            os_log("📋 [Keychain] 无法列出Keychain项，状态码: %d", log: logger, type: .info, listStatus)
        }
        
        // 错误处理
        if status == errSecItemNotFound {
            os_log("❌ [Keychain] 未找到Keychain项 (errSecItemNotFound)", log: logger, type: .error)
            print("❌ [Keychain] 未找到Keychain项，AccessGroup: \(accessGroup)")
            print("💡 [Keychain] 提示: 请确保主应用已登录并存储了认证信息")
            return nil
        }
        
        if status == errSecMissingEntitlement {
            os_log("❌ [Keychain] 缺少权限 (errSecMissingEntitlement)", log: logger, type: .error)
            print("❌ [Keychain] 缺少Keychain访问权限，请检查entitlements配置")
            print("💡 [Keychain] 提示: 确保主应用的entitlements文件包含keychain-access-groups")
            return nil
        }
        
        if status == errSecAuthFailed {
            os_log("❌ [Keychain] 认证失败 (errSecAuthFailed)", log: logger, type: .error)
            print("❌ [Keychain] Keychain认证失败")
            return nil
        }
        
        if status != noErr {
            os_log("❌ [Keychain] 未知错误，状态码: %d", log: logger, type: .error, status)
            print("❌ [Keychain] 读取失败，错误码: \(status)")
            return nil
        }
        
        return nil
    }
}

