//
//  FilterDrawerView.swift
//  Gumroad
//
//  Created by Nathan Chan on 9/18/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI

struct FilterDrawerView: View {
    @Binding var isShowing: Bool
    @Binding var tags: [DiscoverTag]
    @Binding var filetypes: [DiscoverFileType]
    @Binding var shouldReset: Bool
    var tabBarController: MainTabViewController?
    var onApply: (String, String, Int, [DiscoverTag], [DiscoverFileType]) -> Void
    
    @State private var translation = CGSize.zero
    @State private var contentHeight: CGFloat = .zero
    @State private var scrollViewContentHeight: CGFloat = .zero
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var animatedIsShowing: Bool = false
    
    @State var minimumPrice: String = ""
    @State var maximumPrice: String = ""
    @State var selectedRatingMinimum: Int = 0
    @State var selectedTags: [DiscoverTag] = []
    @State var selectedFiletypes: [DiscoverFileType] = []
    
    private var initYOffset: CGFloat {
        let tabBarHeight = (tabBarController?.tabBar.frame.height ?? 0) + 10
        return animatedIsShowing ? (UIScreen.main.bounds.height - contentHeight - tabBarHeight) / 2 : (UIScreen.main.bounds.height + contentHeight + tabBarHeight) / 2
    }
    
    private var yOffset: CGFloat {
        return initYOffset + max(0, translation.height)
    }
    
    var body: some View {
        ZStack {
            if animatedIsShowing {
                Rectangle()
                    .foregroundColor(.black)
                    .opacity(0.5)
                    .animation(.default, value: animatedIsShowing)
                    .onTapGesture {
                        self.isShowing.toggle()
                    }
            }
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
                        .frame(width: 80, height: 4)
                    
                    Color.clear
                        .frame(width: 80, height: 10)
                        .contentShape(Rectangle())
                }
                .padding(.top, 5)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            self.translation = CGSize(width: 0, height: max(0, value.translation.height))
                        }
                        .onEnded { value in
                            if value.translation.height > 20 {
                                self.isShowing.toggle()
                            }
                            self.translation = .zero
                        }
                )
                
                VStack {
                    HStack {
                        Text("Filters")
                            .foregroundColor(Color(UIColor.label))
                            .font(Font.drawerTitleFont)
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                self.isShowing.toggle()
                            }
                        }) {
                            Text("Close")
                                .foregroundColor(Color(UIColor.rgb(red: 120, green: 113, blue: 108)))
                                .font(Font.drawerCloseFont)
                        }
                    }
                }
                .padding(16)
                .frame(minWidth: 0, maxWidth: .infinity)
                .gesture(
                    DragGesture()
                        .onChanged { (value) in
                            self.translation = CGSize(width: 0, height: max(0, value.translation.height))
                        }
                        .onEnded { (value) in
                            if value.translation.height > 20 {
                                self.isShowing.toggle()
                            }
                            self.translation = .zero
                        }
                )
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Price")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Minimum")
                                    Spacer()
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .inset(by: 0.5)
                                        .stroke(Color(UIColor.label), lineWidth: 1)
                                    
                                    HStack {
                                        Circle()
                                            .stroke(lineWidth: 1)
                                            .frame(width: 33, height: 36)
                                            .overlay(
                                                Text("$")
                                            )
                                        
                                        TextField("0", text: $minimumPrice)
                                            .keyboardType(.decimalPad)
                                            .frame(height: 36)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Maximum")
                                    Spacer()
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .inset(by: 0.5)
                                        .stroke(Color(UIColor.label), lineWidth: 1)
                                    
                                    HStack {
                                        Circle()
                                            .stroke(lineWidth: 1)
                                            .frame(width: 33, height: 36)
                                            .overlay(
                                                Text("$")
                                            )
                                        
                                        TextField("∞", text: $maximumPrice)
                                            .keyboardType(.decimalPad)
                                            .frame(height: 36)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
                            
                            HStack {
                                Text("Ratings")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            VStack {
                                ForEach((1...4).reversed(), id: \.self) { i in
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { j in
                                            Image((i >= j) ? "ratings-star-pink" : "ratings-star")
                                                .frame(width: 20, height: 20)
                                        }
                                        Text("and up")
                                            .padding(.horizontal, 4)
                                        Spacer()
                                        Image(selectedRatingMinimum == i ? "filter-selected" : "filter-unselected")
                                            .frame(width: 24, height: 24)
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                selectedRatingMinimum = selectedRatingMinimum == i ? 0 : i
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
                            
                            HStack {
                                Text("Tags")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            VStack {
                                HStack {
                                    Text("All products")
                                    Spacer()
                                    Image(selectedTags.isEmpty ? "filter-selected" : "filter-unselected")
                                        .frame(width: 24, height: 24)
                                        .onTapGesture {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            selectedTags = []
                                        }
                                }
                                ForEach(tags, id: \.key) { tag in
                                    var isSelected = selectedTags.contains(where: { $0.key == tag.key })
                                    HStack {
                                        Text(tag.key)
                                        Spacer()
                                        Image(isSelected ? "filter-selected" : "filter-unselected")
                                            .frame(width: 24, height: 24)
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                if isSelected {
                                                    selectedTags = selectedTags.filter({ $0.key != tag.key })
                                                } else {
                                                    selectedTags.append(tag)
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
                            
                            HStack {
                                Text("Contains")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            
                            VStack {
                                ForEach(filetypes, id: \.key) { filetype in
                                    var isSelected = selectedFiletypes.contains(where: { $0.key == filetype.key })
                                    HStack {
                                        Text(filetype.key)
                                        Spacer()
                                        Image(isSelected ? "filter-selected" : "filter-unselected")
                                            .frame(width: 24, height: 24)
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                if isSelected {
                                                    selectedFiletypes = selectedFiletypes.filter({ $0.key != filetype.key })
                                                } else {
                                                    selectedFiletypes.append(filetype)
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                        .foregroundColor(Color(UIColor.label))
                        .font(Font.drawerSubtitleFont)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(key: ScrollViewContentHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        )
                    }
                    .frame(height: min(scrollViewContentHeight, UIScreen.main.bounds.height * 0.6))
                    .onAppear {
                        scrollViewProxy = proxy
                    }
                }
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
                
                HStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        resetAllFilters()
                    }) {
                        Text("Clear filters")
                            .font(Font.drawerSubtitleFont)
                            .underline()
                            .foregroundColor(Color(UIColor.rgb(red: 128, green: 128, blue: 128)))
                    }
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onApply(minimumPrice, maximumPrice, selectedRatingMinimum, selectedTags, selectedFiletypes)
                        withAnimation {
                            self.isShowing.toggle()
                        }
                    }) {
                        Text("Apply")
                            .font(Font.drawerSubtitleFont)
                            .foregroundColor(Color(UIColor(named: "GumroadBackgroundColor")!))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 38)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(UIColor(named: "GumroadLabelColor")!))
                            )
                    }
                    
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 60)
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                }
            )
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                self.contentHeight = height
            }
            .onPreferenceChange(ScrollViewContentHeightPreferenceKey.self) { height in
                self.scrollViewContentHeight = height
            }
            .background(Color(UIColor(named: "GumroadBackgroundColor")!))
            .cornerRadius(24)
            .shadow(radius: 20)
            .frame(width: UIScreen.main.bounds.width)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
            .offset(x: 0, y: yOffset)
            .animation(Animation.interpolatingSpring(mass: 0.5, stiffness: 45, damping: 45, initialVelocity: 15), value: animatedIsShowing)
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    dismissKeyboard()
                }
            )
            .onTapGesture {
                dismissKeyboard()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: isShowing) { newValue in
            if !isShowing {
                onApply(minimumPrice, maximumPrice, selectedRatingMinimum, selectedTags, selectedFiletypes)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (newValue ? 0.1 : 0)) {
                withAnimation {
                    animatedIsShowing = newValue
                }
            }
        }
        .onChange(of: shouldReset) { newValue in
            if shouldReset {
                shouldReset = false
                resetAllFilters()
            }
        }
    }
    
    private func resetAllFilters() {
        minimumPrice = ""
        maximumPrice = ""
        selectedRatingMinimum = 0
        selectedTags = []
        selectedFiletypes = []
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
