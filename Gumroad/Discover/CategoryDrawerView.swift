//
//  CategoryDrawerView.swift
//  Gumroad
//
//  Created by Nathan Chan on 9/3/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI

struct CategoryDrawerView: View {
    @Binding var isShowing: Bool
    @Binding var isShowingMoreCategories: Bool
    @Binding var selectedCategory: DiscoverCategory?
    @Binding var displayedCategory: DiscoverCategory?
    var allCategories: [DiscoverCategory]
    var tabBarController: MainTabViewController?
    @State private var categoriesToShow: [DiscoverCategory] = []
    
    @State private var translation = CGSize.zero
    @State private var contentHeight: CGFloat = .zero
    @State private var scrollViewContentHeight: CGFloat = .zero
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var animatedIsShowing: Bool = false
    @State private var animatedDisplayedCategory: DiscoverCategory?
    
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
                        if let parentId = animatedDisplayedCategory?.parentId,
                           let parentCategory = allCategories.first(where: { parentId == $0.id }) {
                            HStack(spacing: 4) {
                                Image("outline-chevron-left")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                Text("Back to All \(parentCategory.label)")
                                    .foregroundColor(Color(UIColor.label))
                                    .font(Font.drawerTitleFont)
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    displayedCategory = parentCategory
                                    updateCategoriesToShow()
                                }
                            }
                        } else if isShowingMoreCategories,
                            let animatedDisplayedCategory = animatedDisplayedCategory,
                            animatedDisplayedCategory.parentId == nil {
                             HStack(spacing: 4) {
                                 Image("outline-chevron-left")
                                     .resizable()
                                     .frame(width: 14, height: 14)
                                 Text("Back to More")
                                     .foregroundColor(Color(UIColor.label))
                                     .font(Font.drawerTitleFont)
                             }
                             .onTapGesture {
                                 UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                 withAnimation(.easeInOut(duration: 0.3)) {
                                     self.displayedCategory = nil
                                     updateCategoriesToShow(isMore: true)
                                 }
                             }
                        } else {
                            Text(animatedDisplayedCategory?.label ?? "More")
                                .foregroundColor(Color(UIColor.label))
                                .font(Font.drawerTitleFont)
                        }
                        
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
                        VStack(spacing: 0) {
                            if let animatedDisplayedCategory = animatedDisplayedCategory {
                                CategoryDrawerItemView(category: animatedDisplayedCategory, hasSubCategories: false, isAll: true) { category in
                                    selectedCategory = category
                                    isShowing.toggle()
                                }
                            }
                            ForEach(categoriesToShow) { category in
                                let hasSubCategories = Array(allCategories.filter({ $0.parentId == category.id })).count > 0
                                CategoryDrawerItemView(category: category, hasSubCategories: hasSubCategories) { category in
                                    if hasSubCategories {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            displayedCategory = category
                                            updateCategoriesToShow()
                                        }
                                    } else {
                                        selectedCategory = category
                                        isShowing.toggle()
                                    }
                                }
                            }
                            Spacer()
                                .frame(height: 48)
                        }
                        .id("topAnchor")
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(key: ScrollViewContentHeightPreferenceKey.self, value: geometry.size.height)
                            }
                        )
                    }
                    .frame(height: min(scrollViewContentHeight, UIScreen.main.bounds.height * 0.5))
                    .onAppear {
                        scrollViewProxy = proxy
                    }
                }
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
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: isShowing) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + (newValue ? 0.1 : 0)) {
                withAnimation {
                    animatedIsShowing = newValue
                }
            }
            displayedCategory = isShowingMoreCategories ? nil : displayedCategory
            updateCategoriesToShow(isMore: isShowingMoreCategories)
        }
        .onChange(of: displayedCategory) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedDisplayedCategory = newValue
            }
        }
    }
    
    func updateCategoriesToShow(isMore: Bool = false) {
        categoriesToShow = isMore
            ? Array(allCategories.filter({ $0.parentId == nil }).suffix(from: 5))
            : Array(allCategories.filter({ $0.parentId == displayedCategory?.id }))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollViewProxy?.scrollTo("topAnchor", anchor: .top)
        }
    }
}

struct CategoryDrawerItemView: View {
    var category: DiscoverCategory
    var hasSubCategories: Bool
    var isAll: Bool = false
    var onClick: (DiscoverCategory) -> Void
    
    var body: some View {
        HStack {
            Text("\(isAll ? "All " : "")\(category.label)")
                .font(Font.custom("Mabry Pro", size: 16))
                .underline(!hasSubCategories)
            Spacer()
            if hasSubCategories {
                Image("outline-chevron-right")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onClick(category)
        }
        
        Rectangle()
            .frame(height: 0.5)
            .foregroundColor(Color(UIColor(named: "GumroadDrawerSeparatorColor")!))
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ScrollViewContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
