//
//  ContentView.swift
//  TwoTierPremiumAccessDemo
//
//  Exercises the two inputs (rewarded-ad unlock, subscription) and shows
//  the derived hasPremiumAccess flag flip live.
//

import SwiftUI
import TwoTierPremiumAccess

struct ContentView: View {
    @StateObject private var access = PremiumAccessManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Derived state") {
                    HStack {
                        Text("hasPremiumAccess")
                        Spacer()
                        Text(access.hasPremiumAccess ? "Yes" : "No")
                            .foregroundStyle(access.hasPremiumAccess ? .green : .secondary)
                            .fontWeight(.semibold)
                    }
                    if let expiry = access.adUnlockExpiry {
                        HStack {
                            Text("Unlock expires")
                            Spacer()
                            Text(expiry, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Inputs") {
                    Button("Grant Ad Unlock (1h)") {
                        access.grantAdUnlock()
                    }
                    Toggle("isSubscribed", isOn: $access.isSubscribed)
                    HStack {
                        Text("isAdUnlocked")
                        Spacer()
                        Text(access.isAdUnlocked ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notices") {
                    HStack {
                        Text("Show expiry notice")
                        Spacer()
                        Text(access.showExpiryNotice ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                    Button("Acknowledge expiry notice") {
                        access.acknowledgeExpiryNotice()
                    }
                    .disabled(!access.showExpiryNotice)
                }

                Section("Test") {
                    Button("Grant unlock for 15 seconds") {
                        access.unlockDuration = 15
                        access.grantAdUnlock()
                        access.unlockDuration = 3600
                    }
                    .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Premium Access")
        }
    }
}

#Preview {
    ContentView()
}
