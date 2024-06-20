//
//  ViewExtensions.swift
//  simpl3
//
//  Created by Väinö Kurula on 1.7.2023.
//

import SwiftUI
import UIKit

extension View {
    func adaptiveForegroundColor() -> some View {
        self.foregroundColor(Color.isDarkMode ? .white : .black)
    }
}

extension Color {
    static var isDarkMode: Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
}
