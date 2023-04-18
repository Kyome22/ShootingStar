//
//  ShootingStarApp.swift
//  ShootingStar
//
//  Created by Takuto Nakamura on 2023/04/19.
//

import SwiftUI

@main
struct ShootingStarApp: App {
    @StateObject private var appModel = ShootingStarAppModelImpl()

    var body: some Scene {
        WindowGroup {
            ContentView<ContentViewModelImpl>()
        }
    }
}
