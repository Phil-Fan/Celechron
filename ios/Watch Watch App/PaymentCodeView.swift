//
//  PaymentCodeView.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import SwiftUI

struct PaymentCodeView: View {
    @StateObject private var provider = ECardProvider()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if provider.isLoading {
                    ProgressView()
                        .padding()
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let error = provider.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            provider.loadBarcode()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if !provider.barcode.isEmpty {
                    VStack(spacing: 12) {
                        Text("付款码")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(provider.barcode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        Button("刷新") {
                            provider.loadBarcode()
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
                            provider.loadBarcode()
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
            if provider.barcode.isEmpty {
                provider.loadBarcode()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PaymentCodeView()
    }
}


