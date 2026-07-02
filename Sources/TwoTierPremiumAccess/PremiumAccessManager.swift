//
//  PremiumAccessManager.swift
//  TwoTierPremiumAccess
//
//  Created by Rei Cordero on 2/12/26.
//

import Combine
import Foundation

public final class PremiumAccessManager: ObservableObject {

    public static let shared = PremiumAccessManager()

    @Published public private(set) var isAdUnlocked: Bool = false
    @Published public private(set) var adUnlockExpiry: Date?
    @Published public var isSubscribed: Bool = false
    // Event disguised as state — future: replace with PassthroughSubject<Void, Never>
    @Published public var showExpiryNotice: Bool = false
    @Published public private(set) var hasPremiumAccess: Bool = false

    public var unlockDuration: TimeInterval = 3600
    private let expiryKey = "premiumAdUnlockExpiry"
    private var expiryTimer: AnyCancellable?

    private init() {
        restoreStateFromDefaults()
        setupPremiumAccessBinding()
    }

    private func setupPremiumAccessBinding() {
        Publishers.CombineLatest($isAdUnlocked, $isSubscribed)
            .map { $0 || $1 }
            .removeDuplicates()
            .assign(to: &$hasPremiumAccess)
    }

    public func acknowledgeExpiryNotice() {
        showExpiryNotice = false
    }

    public func grantAdUnlock() {
        let expiry = Date().addingTimeInterval(unlockDuration)
        adUnlockExpiry = expiry
        isAdUnlocked = true
        showExpiryNotice = false
        persistExpiry(expiry)
        scheduleExpiryTimer(at: expiry)
    }

    // MARK: - Persistence

    private func persistExpiry(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: expiryKey)
    }

    private func clearExpiry() {
        UserDefaults.standard.removeObject(forKey: expiryKey)
    }

    private func restoreStateFromDefaults() {
        let stored = UserDefaults.standard.double(forKey: expiryKey)
        guard stored > 0 else { return }

        let expiry = Date(timeIntervalSince1970: stored)
        guard expiry > Date() else {
            clearExpiry()
            showExpiryNotice = true
            return
        }

        adUnlockExpiry = expiry
        isAdUnlocked = true
        scheduleExpiryTimer(at: expiry)
    }

    // MARK: - Timer

    private func scheduleExpiryTimer(at expiry: Date) {
        expiryTimer?.cancel()

        let remaining = max(expiry.timeIntervalSinceNow, 0)

        expiryTimer = Timer.publish(every: remaining, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                guard let self else { return }
                self.isAdUnlocked = false
                self.adUnlockExpiry = nil
                self.showExpiryNotice = true
                self.clearExpiry()
            }
    }
}
