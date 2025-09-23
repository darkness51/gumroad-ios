//
//  ImageCarouselView.swift
//  Gumroad
//
//  Created by Nathan Chan on 6/14/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI
import Combine

struct ImageCarouselView<Content: View>: View {
    private var numberOfImages: Int
    private var content: Content
    @State var slideGesture: CGSize = CGSize.zero
    @State private var currentIndex: Int = 0

    init(numberOfImages: Int, @ViewBuilder content: () -> Content) {
        self.numberOfImages = numberOfImages
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    self.content
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
                .offset(x: CGFloat(self.currentIndex) * -geometry.size.width, y: 0)
                .animation(.spring, value: UUID())
                .gesture(DragGesture().onChanged{ value in
                    self.slideGesture = value.translation
                }
                .onEnded{ value in
                    if self.slideGesture.width < -50 {
                        if self.currentIndex < self.numberOfImages - 1 {
                            withAnimation {
                                self.currentIndex += 1
                            }
                        }
                    }
                    if self.slideGesture.width > 50 {
                        if self.currentIndex > 0 {
                            withAnimation {
                                self.currentIndex -= 1
                            }
                        }
                    }
                    self.slideGesture = .zero
                })
                
                if self.numberOfImages > 1 {
                    HStack(spacing: 3) {
                        ForEach(0..<self.numberOfImages, id: \.self) { index in
                            Circle()
                                .frame(width: index == self.currentIndex ? 10 : 8,
                                       height: index == self.currentIndex ? 10 : 8)
                                .foregroundColor(index == self.currentIndex ? .black : .white)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .padding(.bottom, 8)
                                .animation(.spring())
                        }
                    }
                }
            }
        }
    }
}
