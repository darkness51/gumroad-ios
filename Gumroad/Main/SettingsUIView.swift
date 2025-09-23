//
//  SettingsUIView.swift
//  Gumroad
//
//  Created by Nathan Chan on 3/19/24.
//  Copyright © 2024 Gumroad. All rights reserved.
//

import SwiftUI

struct SettingsUIView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode

    var onLogoutCompleted: (() -> Void)

    @State var showLogoutAlert = false

    var body: some View {
        VStack {
            VStack {
                Spacer()
                ZStack {
                    HStack {
                        Button(action: closeClicked) {
                            Image("cancel-white")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        Spacer()
                    }
                    Text("Settings")
                        .font(Font.bannerTitleFont)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 40)
                }
            }
            .padding(16)
            .frame(height: 80)
            .background(Color.black)

            VStack {
                VStack(spacing: 20) {
                    Text("Account")
                        .font(Font.settingsHeaderFont)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Text("This will log you out of your Gumroad account.")
                        .font(Font.settingsTextFont)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Button {
                        showLogoutAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Spacer()
                            Text("Logout")
                                .foregroundColor(Color(UIColor.systemBackground))
                                .font(Font.settingsButtonFont)
                                .padding(.vertical, 16)
                            Image("logout")
                                .frame(width: 18, height: 18)
                                .padding(.vertical, 16)
                            Spacer()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor(named: "GumroadLabelColor")!))
                        )
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Are you sure?"),
                            message: nil,
                            primaryButton: .destructive(Text("Logout")) {
                                logout()
                            },
                            secondaryButton: .cancel(Text("Cancel"))
                        )
                    }
                }

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor(named: "GumroadBorderColor")!))
                    .padding(.vertical, 32)

                VStack(spacing: 20) {
                    Text("Danger Zone")
                        .font(Font.settingsHeaderFont)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Text("Deleting your account will delete all of your products and product files, as well as any credit card and payout information.")
                        .font(Font.settingsTextFont)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Button {
                        logEvent("delete_account_clicked")
                        UIApplication.shared.open(URL(string: "https://gumroad.com/settings/advanced")!)
                    } label: {
                        HStack(spacing: 4) {
                            Spacer()
                            Text("Go to account deletion page")
                                .font(Font.settingsButtonFont)
                                .padding(.vertical, 16)
                            Image(systemName: "arrow.right")
                                .frame(width: 18, height: 18)
                                .padding(.vertical, 16)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .background(Color(red: 0.86, green: 0.2, blue: 0.12))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.black, lineWidth: 1)
                        )
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Are you sure?"),
                            message: nil,
                            primaryButton: .destructive(Text("Logout")) {
                                logout()
                            },
                            secondaryButton: .cancel(Text("Cancel"))
                        )
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .background(Color(UIColor(named: "GumroadTopViewColor")!))
    }

    func closeClicked() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        presentationMode.wrappedValue.dismiss()
    }

    func logout() {
        GRDLoginManager.sharedInstance.logout()
        presentationMode.wrappedValue.dismiss()
        onLogoutCompleted()
    }
}

#Preview {
    SettingsUIView(onLogoutCompleted: {})
}
