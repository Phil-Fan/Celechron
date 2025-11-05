//
//  ContentView.swift
//  Watch Watch App
//
//  Created by PhilFan on 2025/11/5.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink(destination: PaymentCodeView()) {
                    HStack {
                        Image(systemName: "qrcode")
                            .font(.title2)
                        Text("付款码")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: ScheduleListView()) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title2)
                        Text("日程")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .navigationTitle("Celechron")
        }
        .onAppear {
            print("📱 [ContentView] Watch应用主界面已加载")
        }
    }
}

#Preview {
    ContentView()
}
