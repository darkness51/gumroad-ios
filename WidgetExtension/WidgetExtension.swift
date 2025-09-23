//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by Nathan Chan on 10/17/23.
//  Copyright © 2023 Gumroad. All rights reserved.
//

import WidgetKit
import SwiftUI
import NXOAuth2Client

let sampleSimpleEntry = SimpleEntry(
    date: Date(),
    timeRangeRevenueMap: [
        "day": "$3,393",
        "week": "$30,044",
        "month": "$80,040",
        "year": "$230,334"
    ],
    isLoggedIn: true,
    hasError: false
)

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        sampleSimpleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(sampleSimpleEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        if let accountObj = UserDefaults(suiteName: appGroupName)?.value(forKey: accountObjectUserDefaultsKey) as? Data,
           let account = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(accountObj) as? NXOAuth2Account {
            WidgetNetworkRequest.shared.fetchRevenueTotals(with: account, successBlock: { (response, responseObject) -> Void in
                let data = responseObject as! [AnyHashable: Any]
                if let dayRevenueString = (data["day"] as? [String: Any])?["formatted_revenue"] as? String,
                   let weekRevenueString = (data["week"] as? [String: Any])?["formatted_revenue"] as? String,
                   let monthRevenueString = (data["month"] as? [String: Any])?["formatted_revenue"] as? String,
                   let yearRevenueString = (data["year"] as? [String: Any])?["formatted_revenue"] as? String
                {
                    let entry = SimpleEntry(
                        date: Date(),
                        timeRangeRevenueMap: [
                            "day": dayRevenueString,
                            "week": weekRevenueString,
                            "month": monthRevenueString,
                            "year": yearRevenueString
                        ],
                        isLoggedIn: true,
                        hasError: false
                    )
                    let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)
                } else {
                    let entry = SimpleEntry(
                        date: Date(),
                        timeRangeRevenueMap: [:],
                        isLoggedIn: true,
                        hasError: true
                    )
                    let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)
                }
            }, failureBlock: { (error) -> Void in
                print("error: \(error.localizedDescription)")
            })
        } else {
            print("no account stored in user defaults") // ie. not logged in
            let entry = SimpleEntry(date: Date(), timeRangeRevenueMap: [:], isLoggedIn: false, hasError: false)
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timeRangeRevenueMap: [String: String]
    let isLoggedIn: Bool
    let hasError: Bool
}

struct WidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if !entry.isLoggedIn {
            VStack {
                HStack {
                    Image("logo-small")
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .aspectRatio(contentMode: .fit)
                    Text("Click to login")
                        .font(Font.gumroadFontBold)
                        .foregroundColor(Color(UIColor.label))
                }
            }
            .padding(8)
            .widgetBackground(Color(UIColor.systemBackground))
        } else if entry.hasError {
            VStack(alignment: .center) {
                Spacer()
                Image("logo-small")
                    .resizable()
                    .frame(width: 20, height: 20, alignment: .center)
                    .aspectRatio(contentMode: .fit)
                Text("Sorry, something went wrong. Try again later.")
                    .font(Font.gumroadFont)
                    .foregroundColor(Color(UIColor.label))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(16)
            .widgetBackground(Color(UIColor.systemBackground))
        } else {
            VStack {
                HStack {
                    Image("logo-small")
                        .resizable()
                        .frame(width: 20, height: 20, alignment: .center)
                        .aspectRatio(contentMode: .fit)
                    Spacer()
                        .frame(width: 5)
                    Text("Gumroad Totals")
                        .font(Font.gumroadFontBold)
                        .foregroundColor(Color(UIColor.label))
                }
                Spacer()
                    .frame(height: 16)
                VStack {
                    HStack {
                        timeRangeText("Today")
                        Spacer()
                        revenueText(entry.timeRangeRevenueMap["day"]!)
                    }
                    Spacer()
                        .frame(height: 8)
                    HStack {
                        timeRangeText("Week")
                        Spacer()
                        revenueText(entry.timeRangeRevenueMap["week"]!)
                    }
                    Spacer()
                        .frame(height: 8)
                    HStack {
                        timeRangeText("Month")
                        Spacer()
                        revenueText(entry.timeRangeRevenueMap["month"]!)
                    }
                    Spacer()
                        .frame(height: 8)
                    HStack {
                        timeRangeText("Year")
                        Spacer()
                        revenueText(entry.timeRangeRevenueMap["year"]!)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .widgetBackground(Color(UIColor.systemBackground))
        }
    }
}

func timeRangeText(_ text: String) -> Text {
    return Text(text)
        .font(Font.gumroadFont)
        .foregroundColor(Color(UIColor.label))
}

func revenueText(_ text: String) -> Text {
    return Text(text)
        .font(Font.gumroadFontBold)
        .foregroundColor(Color(UIColor.label))
}

//@main
struct WidgetExtension: Widget {
    init() {
        // Setup login oauth information
        let oauthAppInformation = WidgetNetworkRequest.shared.fetchOAuthApplicationInformation
        let clientID = oauthAppInformation["client_id"]
        let secret = oauthAppInformation["secret_id"]
        let authorizationURL = oauthAppInformation["authorization_url"]
        let tokenURL = oauthAppInformation["token_url"]
        let redirectURL = oauthAppInformation["redirect_uri"]

        let accountTypes = ["Gumroad", "Twitter", "Facebook", "Apple", "Google"]
        for accountType in accountTypes {
            (NXOAuth2AccountStore.sharedStore() as! NXOAuth2AccountStore).setClientID(clientID,
                secret: secret,
                scope: NSSet(object: "creator_api") as Set<NSObject>,
                authorizationURL: URL(string: authorizationURL!),
                tokenURL: URL(string: tokenURL!),
                redirectURL: URL(string: redirectURL!),
                keyChainGroup: "gumroad",
                forAccountType: accountType
            )
        }
    }

    let kind: String = "WidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetExtensionEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Gumroad")
        .description("Analytics")
        .supportedFamilies([.systemSmall])
    }
}

struct WidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        WidgetExtensionEntryView(entry: sampleSimpleEntry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
