/*
  ShootingStarAppModel.swift
  ShootingStar

  Created by Takuto Nakamura on 2023/04/19.
  
*/

import SwiftUI
import Combine

protocol ShootingStarAppModel: ObservableObject {}

final class ShootingStarAppModelImpl: ShootingStarAppModel {
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: UIApplication.didFinishLaunchingNotification)
            .sink { [weak self] _ in
                self?.applicationDidFinishLaunching()
            }
            .store(in: &cancellables)
        NotificationCenter.default
            .publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.applicationWillTerminate()
            }
            .store(in: &cancellables)
    }

    private func applicationDidFinishLaunching() {}

    private func applicationWillTerminate() {}
}

// MARK: - Preview Mock
extension PreviewMock {
    final class ShootingStarAppModelMock: ShootingStarAppModel {}
}
