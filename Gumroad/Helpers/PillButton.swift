//
//  PillButton.swift
//  Gumroad
//
//  Created by Nathan Chan on 9/11/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import Foundation
import SwiftUI

struct PillButton: View {
    let title: String
    let imageName: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, imageName: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.imageName = imageName
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack {
                Text(title)
                    .font(Font.pillButtonFont)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(UIColor.label))
                if let imageName = imageName {
                    Spacer(minLength: 8)
                    Image(imageName)
                        .resizable()
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 36, alignment: .center)
            .background(isSelected ? Color(UIColor.systemBackground) : .clear)
            .cornerRadius(160)
            .overlay(
                RoundedRectangle(cornerRadius: 160)
                    .inset(by: 0.5)
                    .stroke(Color(UIColor.label), lineWidth: isSelected ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
