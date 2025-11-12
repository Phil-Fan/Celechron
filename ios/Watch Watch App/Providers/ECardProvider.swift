//
//  ECardProvider.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import Foundation
import Combine

@MainActor
class ECardProvider: ObservableObject {
    @Published var barcode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    func loadBarcode() {
        print("🔄 [ECardProvider] 开始加载付款码")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔍 [ECardProvider] 步骤1: 从Keychain读取认证信息")
                guard let synjonesAuth = KeychainHelper.getSynjonesAuth() else {
                    print("❌ [ECardProvider] Keychain中没有认证信息")
                    errorMessage = "未登录\n\n请先在主应用中登录"
                    isLoading = false
                    return
                }
                
                print("✅ [ECardProvider] 成功获取认证信息，长度: \(synjonesAuth.count)")
                
                // 测试账号处理
                if synjonesAuth == "3200000000" {
                    print("🧪 [ECardProvider] 检测到测试账号，生成随机付款码")
                    let randomCode = String((0..<16).map { _ in "0123456789".randomElement()! })
                    barcode = randomCode
                    isLoading = false
                    print("✅ [ECardProvider] 测试付款码生成成功: \(randomCode)")
                    return
                }
                
                // 获取账户
                print("🔍 [ECardProvider] 步骤2: 获取校园卡账户")
                guard let eCardAccount = try await NetworkHelper.getECardAccount(synjonesAuth: synjonesAuth) else {
                    print("❌ [ECardProvider] 获取账户失败")
                    errorMessage = "获取账户失败"
                    isLoading = false
                    return
                }
                
                print("✅ [ECardProvider] 成功获取账户: \(eCardAccount)")
                
                // 获取付款码
                print("🔍 [ECardProvider] 步骤3: 获取付款码")
                guard let code = try await NetworkHelper.getBarcode(synjonesAuth: synjonesAuth, eCardAccount: eCardAccount) else {
                    print("❌ [ECardProvider] 获取付款码失败")
                    errorMessage = "获取付款码失败"
                    isLoading = false
                    return
                }
                
                print("✅ [ECardProvider] 成功获取付款码: \(code)")
                barcode = code
                isLoading = false
                print("✅ [ECardProvider] 付款码加载完成")
            } catch {
                print("❌ [ECardProvider] 发生错误: \(error.localizedDescription)")
                errorMessage = "网络错误: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

