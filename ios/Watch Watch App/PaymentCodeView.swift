//
//  PaymentCodeView.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import SwiftUI

struct PaymentCodeView: View {
    @State private var barcode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding()
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            loadBarcode()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if !barcode.isEmpty {
                    VStack(spacing: 12) {
                        Text("付款码")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(barcode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        Button("刷新") {
                            loadBarcode()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        Text("暂无付款码")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("加载") {
                            loadBarcode()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("付款码")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if barcode.isEmpty {
                loadBarcode()
            }
        }
    }
    
    private func loadBarcode() {
        print("🔄 [PaymentCodeView] 开始加载付款码")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔍 [PaymentCodeView] 步骤1: 从Keychain读取认证信息")
                guard let synjonesAuth = KeychainHelper.getSynjonesAuth() else {
                    print("❌ [PaymentCodeView] Keychain中没有认证信息")
                    await MainActor.run {
                        errorMessage = "未登录"
                        isLoading = false
                    }
                    return
                }
                
                print("✅ [PaymentCodeView] 成功获取认证信息，长度: \(synjonesAuth.count)")
                
                // 测试账号处理
                if synjonesAuth == "3200000000" {
                    print("🧪 [PaymentCodeView] 检测到测试账号，生成随机付款码")
                    let randomCode = String((0..<16).map { _ in "0123456789".randomElement()! })
                    await MainActor.run {
                        barcode = randomCode
                        isLoading = false
                    }
                    print("✅ [PaymentCodeView] 测试付款码生成成功: \(randomCode)")
                    return
                }
                
                // 获取账户
                print("🔍 [PaymentCodeView] 步骤2: 获取校园卡账户")
                guard let eCardAccount = try await NetworkHelper.getECardAccount(synjonesAuth: synjonesAuth) else {
                    print("❌ [PaymentCodeView] 获取账户失败")
                    await MainActor.run {
                        errorMessage = "获取账户失败"
                        isLoading = false
                    }
                    return
                }
                
                print("✅ [PaymentCodeView] 成功获取账户: \(eCardAccount)")
                
                // 获取付款码
                print("🔍 [PaymentCodeView] 步骤3: 获取付款码")
                guard let code = try await NetworkHelper.getBarcode(synjonesAuth: synjonesAuth, eCardAccount: eCardAccount) else {
                    print("❌ [PaymentCodeView] 获取付款码失败")
                    await MainActor.run {
                        errorMessage = "获取付款码失败"
                        isLoading = false
                    }
                    return
                }
                
                print("✅ [PaymentCodeView] 成功获取付款码: \(code)")
                await MainActor.run {
                    barcode = code
                    isLoading = false
                }
                print("✅ [PaymentCodeView] 付款码加载完成")
            } catch {
                print("❌ [PaymentCodeView] 发生错误: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "网络错误: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaymentCodeView()
    }
}

