//
//  TrafficViewController.swift
//  iOSCreator
//
//  Created by Nathan Chan on 7/27/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit
import Charts

class TrafficViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .creator

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var revenueHighlightedDateLabel: UILabel!
    @IBOutlet weak var revenueLegendStackView: UIStackView!
    @IBOutlet weak var revenueHighlightedLegendStackView: UIStackView!
    @IBOutlet weak var revenueBarChartView: BarChartView!
    @IBOutlet weak var revenueNoDataView: UIView!
    @IBOutlet weak var revenueLoadingImageView: UIImageView!
    @IBOutlet weak var visitsHighlightedDateLabel: UILabel!
    @IBOutlet weak var visitsLegendStackView: UIStackView!
    @IBOutlet weak var visitsHighlightedLegendStackView: UIStackView!
    @IBOutlet weak var visitsBarChartView: BarChartView!
    @IBOutlet weak var visitsNoDataView: UIView!
    @IBOutlet weak var visitsLoadingImageView: UIImageView!
    @IBOutlet weak var salesHighlightedDateLabel: UILabel!
    @IBOutlet weak var salesLegendStackView: UIStackView!
    @IBOutlet weak var salesHighlightedLegendStackView: UIStackView!
    @IBOutlet weak var salesBarChartView: BarChartView!
    @IBOutlet weak var salesNoDataView: UIView!
    @IBOutlet weak var salesLoadingImageView: UIImageView!

    let pulseAnimation = CABasicAnimation(keyPath: "opacity")
    let pulseAnimationKey = "pulseAnimation"

    let revenueBarChartViewName = "revenueBarChartView"
    let visitsBarChartViewName = "visitsBarChartView"
    let salesBarChartViewName = "salesBarChartView"

    var revenueToDisplayMap: [String: [Int]] = [:]
    var revenueToDisplayArray: [Dictionary<String, [Int]>.Element] = []
    var salesToDisplayMap: [String: [Int]] = [:]
    var salesToDisplayArray: [Dictionary<String, [Int]>.Element] = []
    var visitsToDisplayMap: [String: [Int]] = [:]
    var visitsToDisplayArray: [Dictionary<String, [Int]>.Element] = []
    var zeroRevenueValue: Double = 0
    var zeroVisitsValue: Double = 0
    var zeroSalesValue: Double = 0

    var lastDateRangeFetched = DateRange.week

    var gumroadStackedBarColors = [
        UIColor.gumroadGray400,
        UIColor.gumroadGreen,
        UIColor.gumroadRed,
        UIColor.gumroadYellow
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        revenueBarChartView.delegate = self
        revenueBarChartView.accessibilityLabel = revenueBarChartViewName
        revenueBarChartView.xAxis.enabled = true
        revenueBarChartView.xAxis.axisLineColor = UIColor(named: "GumroadBorderColor")!
        revenueBarChartView.xAxis.axisLineWidth = 1
        revenueBarChartView.xAxis.labelPosition = .bottom
        revenueBarChartView.xAxis.drawLabelsEnabled = false
        revenueBarChartView.xAxis.drawAxisLineEnabled = true
        revenueBarChartView.xAxis.drawGridLinesEnabled = false
        revenueBarChartView.leftAxis.enabled = false
        revenueBarChartView.leftAxis.axisMinimum = 0
        revenueBarChartView.rightAxis.enabled = false
        revenueBarChartView.highlightFullBarEnabled = false
        revenueBarChartView.drawGridBackgroundEnabled = false
        revenueBarChartView.pinchZoomEnabled = false
        revenueBarChartView.doubleTapToZoomEnabled = false
        revenueBarChartView.legend.enabled = false
//        revenueBarChartView.dragEnabled = false

        visitsBarChartView.delegate = self
        visitsBarChartView.accessibilityLabel = visitsBarChartViewName
        visitsBarChartView.xAxis.enabled = true
        visitsBarChartView.xAxis.axisLineColor = UIColor(named: "GumroadBorderColor")!
        visitsBarChartView.xAxis.axisLineWidth = 1
        visitsBarChartView.xAxis.labelPosition = .bottom
        visitsBarChartView.xAxis.drawLabelsEnabled = false
        visitsBarChartView.xAxis.drawAxisLineEnabled = true
        visitsBarChartView.xAxis.drawGridLinesEnabled = false
        visitsBarChartView.leftAxis.enabled = false
        visitsBarChartView.leftAxis.axisMinimum = 0
        visitsBarChartView.rightAxis.enabled = false
        visitsBarChartView.drawGridBackgroundEnabled = false
        visitsBarChartView.pinchZoomEnabled = false
        visitsBarChartView.doubleTapToZoomEnabled = false
        visitsBarChartView.legend.enabled = false
//        visitsBarChartView.dragEnabled = false

        salesBarChartView.delegate = self
        salesBarChartView.accessibilityLabel = salesBarChartViewName
        salesBarChartView.xAxis.enabled = true
        salesBarChartView.xAxis.axisLineColor = UIColor(named: "GumroadBorderColor")!
        salesBarChartView.xAxis.axisLineWidth = 1
        salesBarChartView.xAxis.labelPosition = .bottom
        salesBarChartView.xAxis.drawLabelsEnabled = false
        salesBarChartView.xAxis.drawAxisLineEnabled = true
        salesBarChartView.xAxis.drawGridLinesEnabled = false
        salesBarChartView.leftAxis.enabled = false
        salesBarChartView.leftAxis.axisMinimum = 0
        salesBarChartView.rightAxis.enabled = false
        salesBarChartView.drawGridBackgroundEnabled = false
        salesBarChartView.pinchZoomEnabled = false
        salesBarChartView.doubleTapToZoomEnabled = false
        salesBarChartView.legend.enabled = false
//        salesBarChartView.dragEnabled = false

        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 0
        pulseAnimation.toValue = UITraitCollection.current.userInterfaceStyle == .dark ? 0.2 : 1
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude

        let initSelectedIndex = 0
        (stackView.arrangedSubviews[initSelectedIndex] as? UIButton)?.isSelected = true
        updateData(with: DateRange.allCases[initSelectedIndex])

        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: NSNotification.Name(rawValue: GRDNotificationStrings.pushNotificationReceivedNotificationString()), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: GRDNotificationStrings.pushNotificationReceivedNotificationString()), object: nil)
    }

    @objc func refreshData() {
        for button in stackView.arrangedSubviews.compactMap({ $0 as? UIButton }) {
            button.isSelected = false
        }
        let initSelectedIndex = 0
        (stackView.arrangedSubviews[initSelectedIndex] as? UIButton)?.isSelected = true
        updateData(with: DateRange.allCases[initSelectedIndex])
    }

    func updateData(with dateRange: DateRange) {
        revenueLoadingImageView.image = UIImage(named: "loading-\(dateRange.rawValue)")
        revenueLoadingImageView.layer.add(pulseAnimation, forKey: pulseAnimationKey)
        revenueLegendStackView.isHidden = true
        revenueHighlightedLegendStackView.isHidden = true
        revenueNoDataView.isHidden = true
        revenueLoadingImageView.isHidden = false
        visitsLoadingImageView.image = UIImage(named: "loading-\(dateRange.rawValue)")
        visitsLoadingImageView.layer.add(pulseAnimation, forKey: pulseAnimationKey)
        visitsLegendStackView.isHidden = true
        visitsHighlightedLegendStackView.isHidden = true
        visitsNoDataView.isHidden = true
        visitsLoadingImageView.isHidden = false
        salesLoadingImageView.image = UIImage(named: "loading-\(dateRange.rawValue)")
        salesLoadingImageView.layer.add(pulseAnimation, forKey: pulseAnimationKey)
        salesLegendStackView.isHidden = true
        salesHighlightedLegendStackView.isHidden = true
        salesNoDataView.isHidden = true
        salesLoadingImageView.isHidden = false

        lastDateRangeFetched = dateRange

        GRDNetworkRequest.shared.fetchAnalyticsByReferral(dateRange, successBlock: { [self] (response, responseObject) -> Void in
            if lastDateRangeFetched != dateRange { return }

            guard let data = responseObject as? [String: Any] else { return }
            guard let dateStrings = data["dates"] as? [String] else { return }
            guard let byReferralMap = (data["by_referral"]) as? [String: Any] else { return }
            guard let revenueMap = byReferralMap["totals"] as? [String: Any] else { return }
            guard let salesMap = byReferralMap["sales"] as? [String: Any] else { return }
            guard let visitsMap = byReferralMap["views"] as? [String: Any] else { return }

            let keyFind = "direct"
            let keyReplace = "Direct, email, IM"
            let otherKey = "Other"
            let topReferrerCount = 3

            let revenueArray = Array(revenueMap.values).compactMap({ $0 as? [String: [Int]] }).flatMap({ $0 })
            var allRevenueMap: [String: [Int]] = [:]
            for i in 0 ..< revenueArray.count {
                let key = revenueArray[i].key == keyFind ? keyReplace : revenueArray[i].key
                if allRevenueMap[key] == nil {
                    allRevenueMap[key] = revenueArray[i].value
                } else {
                    var tempValues = allRevenueMap[key]!
                    for j in 0 ..< dateStrings.count {
                        tempValues[j] += (revenueArray[i].value)[safe: j] ?? 0
                    }
                    allRevenueMap[key] = tempValues
                }
            }
            var revenueTotalsMap: [String: Int] = [:]
            allRevenueMap.forEach({ k, v in revenueTotalsMap[k] = v.reduce(0, +) })
            let topRevenueReferrers = Set(
                Array(revenueTotalsMap.sorted(by: { $0.value > $1.value })[...min(revenueTotalsMap.count - 1, topReferrerCount - 1)])
                .map({ $0.key }))
            revenueToDisplayMap = [:]
            var otherRevenueValues = [Int](repeating: 0, count: dateStrings.count)
            for (k, v) in allRevenueMap {
                if topRevenueReferrers.contains(k) {
                    revenueToDisplayMap[k] = v
                } else {
                    for i in 0 ..< v.count {
                        otherRevenueValues[i] += v[i]
                    }
                }
            }
            if !otherRevenueValues.allSatisfy({ $0 == 0 }) {
                revenueToDisplayMap[otherKey] = otherRevenueValues
            }

            let visitsArray = Array(visitsMap.values).compactMap({ $0 as? [String: [Int]] }).flatMap({ $0 })
            var allVisitsMap: [String: [Int]] = [:]
            for i in 0 ..< visitsArray.count {
                let key = visitsArray[i].key == keyFind ? keyReplace : visitsArray[i].key
                if allVisitsMap[key] == nil {
                    allVisitsMap[key] = visitsArray[i].value
                } else {
                    var tempValues = allVisitsMap[key]!
                    for j in 0 ..< dateStrings.count {
                        tempValues[j] += (visitsArray[i].value)[safe: j] ?? 0
                    }
                    allVisitsMap[key] = tempValues
                }
            }
            var visitsTotalsMap: [String: Int] = [:]
            allVisitsMap.forEach({ k, v in visitsTotalsMap[k] = v.reduce(0, +) })
            let topVisitsReferrers = Set(
                Array(visitsTotalsMap.sorted(by: { $0.value > $1.value })[...min(visitsTotalsMap.count - 1, topReferrerCount - 1)])
                .map({ $0.key }))
            visitsToDisplayMap = [:]
            var otherVisitsValues = [Int](repeating: 0, count: dateStrings.count)
            for (k, v) in allVisitsMap {
                if topVisitsReferrers.contains(k) {
                    visitsToDisplayMap[k] = v
                } else {
                    for i in 0 ..< v.count {
                        otherVisitsValues[i] += v[i]
                    }
                }
            }
            if !otherVisitsValues.allSatisfy({ $0 == 0 }) {
                visitsToDisplayMap[otherKey] = otherVisitsValues
            }

            let salesArray = Array(salesMap.values).compactMap({ $0 as? [String: [Int]] }).flatMap({ $0 })
            var allSalesMap: [String: [Int]] = [:]
            for i in 0 ..< salesArray.count {
                let key = salesArray[i].key == keyFind ? keyReplace : salesArray[i].key
                if allSalesMap[key] == nil {
                    allSalesMap[key] = salesArray[i].value
                } else {
                    var tempValues = allSalesMap[key]!
                    for j in 0 ..< dateStrings.count {
                        tempValues[j] += (salesArray[i].value)[safe: j] ?? 0
                    }
                    allSalesMap[key] = tempValues
                }
            }
            var salesTotalsMap: [String: Int] = [:]
            allSalesMap.forEach({ k, v in salesTotalsMap[k] = v.reduce(0, +) })
            let topSalesReferrers = Set(
                Array(salesTotalsMap.sorted(by: { $0.value > $1.value })[...min(salesTotalsMap.count - 1, topReferrerCount - 1)])
                .map({ $0.key }))
            salesToDisplayMap = [:]
            var otherSalesValues = [Int](repeating: 0, count: dateStrings.count)
            for (k, v) in allSalesMap {
                if topSalesReferrers.contains(k) {
                    salesToDisplayMap[k] = v
                } else {
                    for i in 0 ..< v.count {
                        otherSalesValues[i] += v[i]
                    }
                }
            }
            if !otherSalesValues.allSatisfy({ $0 == 0 }) {
                salesToDisplayMap[otherKey] = otherSalesValues
            }

            revenueHighlightedDateLabel.text = dateStrings[dateStrings.count - 1]
            visitsHighlightedDateLabel.text = dateStrings[dateStrings.count - 1]
            salesHighlightedDateLabel.text = dateStrings[dateStrings.count - 1]

            var revenueDataEntries: [BarChartDataEntry] = []
            revenueToDisplayArray = Array(revenueToDisplayMap.filter({ $0.key != otherKey }).sorted(by: { $0.key.localizedCompare($1.key) == .orderedDescending }))
            if let otherElement = revenueToDisplayMap.first(where: { $0.key == otherKey }) {
                revenueToDisplayArray.insert(otherElement, at: 0)
            }
            // handle $0 values
            var allRevenueTotals: [Double] = []
            for i in 0 ..< dateStrings.count {
                let sum = revenueToDisplayArray.map({ Double($0.value[i]) }).reduce(0, +)
                if sum > 0 {
                    allRevenueTotals.append(sum)
                }
            }
            let maxRevenueTotalsValue = allRevenueTotals.max() ?? 0
            let minRevenueTotalsValue = allRevenueTotals.min() ?? 0
            zeroRevenueValue = min(minRevenueTotalsValue, maxRevenueTotalsValue / 75)
            while(true) {
                if allRevenueTotals.contains(zeroRevenueValue) {
                    zeroRevenueValue -= 1
                } else {
                    break
                }
            }
            for i in 0 ..< dateStrings.count {
                var yValues = revenueToDisplayArray.map({ Double($0.value[i]) })
                if yValues.reduce(0, +) == 0 {
                    yValues = [Double](repeating: 0.0, count: yValues.count)
                    if yValues.isEmpty {
                        yValues = [zeroRevenueValue]
                    } else {
                        yValues[0] = zeroRevenueValue
                    }
                }
                revenueDataEntries.append(BarChartDataEntry(x: Double(i), yValues: yValues, data: dateStrings[i]))
            }

            let revenueChartDataSet = BarChartDataSet(entries: revenueDataEntries)
            revenueChartDataSet.colors = Array(gumroadStackedBarColors.map({ $0.withAlphaComponent(0.15) }).prefix(max(1, revenueToDisplayArray.count)))
            revenueChartDataSet.highlightEnabled = true
            revenueChartDataSet.drawValuesEnabled = false
            let revenueChartData = BarChartData(dataSet: revenueChartDataSet)
            revenueBarChartView.data = revenueChartData
            (revenueBarChartView.data as? BarChartData)?.barWidth = 0.714
            revenueBarChartView.highlightValues((0..<revenueToDisplayMap.count).map({ Highlight(x: Double(revenueChartDataSet.count - 1), dataSetIndex: 0, stackIndex: $0) }))

            for subview in revenueLegendStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for i in 0..<revenueToDisplayArray.count {
                let index = revenueToDisplayArray.count - i - 1
                let revenueEntry = revenueToDisplayArray[index]
                revenueLegendStackView.addArrangedSubview(LegendView(height: 13, color: gumroadStackedBarColors[index], name: revenueEntry.key, value: "(\((Double(revenueEntry.value.reduce(0, +)) / 100).dollarFormat()))"))
            }
            revenueLegendStackView.isHidden = false

            for subview in revenueHighlightedLegendStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for i in 0..<revenueToDisplayArray.count {
                let index = revenueToDisplayArray.count - i - 1
                let revenueEntry = revenueToDisplayArray[index]
                if let revenueValue = revenueEntry.value.last, revenueValue > 0 {
                    revenueHighlightedLegendStackView.addArrangedSubview(LegendView(height: 10, color: gumroadStackedBarColors[index], name: revenueEntry.key, value: "(\((Double(revenueValue) / 100).dollarFormat()))"))
                }
            }
            revenueHighlightedLegendStackView.isHidden = false

            let revenueIsAllZero = revenueToDisplayArray.flatMap({ $0.value }).allSatisfy({ $0 == 0 })
            revenueNoDataView.isHidden = !revenueIsAllZero
            revenueHighlightedDateLabel.isHidden = revenueIsAllZero
            revenueBarChartView.isUserInteractionEnabled = !revenueIsAllZero
            revenueLoadingImageView.isHidden = true

            var visitsDataEntries: [BarChartDataEntry] = []
            visitsToDisplayArray = Array(visitsToDisplayMap.filter({ $0.key != otherKey }).sorted(by: { $0.key.localizedCompare($1.key) == .orderedDescending }))
            if let otherElement = visitsToDisplayMap.first(where: { $0.key == otherKey }) {
                visitsToDisplayArray.insert(otherElement, at: 0)
            }
            // handle $0 values
            var allVisitsTotals: [Double] = []
            for i in 0 ..< dateStrings.count {
                let sum = visitsToDisplayArray.map({ Double($0.value[i]) }).reduce(0, +)
                if sum > 0 {
                    allVisitsTotals.append(sum)
                }
            }
            let maxVisitsTotalsValue = allVisitsTotals.max() ?? 0
            let minVisitsTotalsValue = allVisitsTotals.min() ?? 0
            zeroVisitsValue = min(minVisitsTotalsValue, maxVisitsTotalsValue / 75)
            while(true) {
                if allVisitsTotals.contains(zeroVisitsValue) {
                    zeroVisitsValue -= 0.01
                } else {
                    break
                }
            }
            for i in 0 ..< dateStrings.count {
                var yValues = visitsToDisplayArray.map({ Double($0.value[i]) })
                if yValues.reduce(0, +) == 0 {
                    yValues = [Double](repeating: 0.0, count: yValues.count)
                    if yValues.isEmpty {
                        yValues = [zeroVisitsValue]
                    } else {
                        yValues[0] = zeroVisitsValue
                    }
                }
                visitsDataEntries.append(BarChartDataEntry(x: Double(i), yValues: yValues, data: dateStrings[i]))
            }
            let visitsChartDataSet = BarChartDataSet(entries: visitsDataEntries)
            visitsChartDataSet.colors = Array(gumroadStackedBarColors.map({ $0.withAlphaComponent(0.15) }).prefix(max(1, visitsToDisplayArray.count)))
            visitsChartDataSet.highlightEnabled = true
            visitsChartDataSet.drawValuesEnabled = false
            let visitsChartData = BarChartData(dataSet: visitsChartDataSet)
            visitsBarChartView.data = visitsChartData
            (visitsBarChartView.data as? BarChartData)?.barWidth = 0.714
            visitsBarChartView.highlightValues((0..<visitsToDisplayMap.count).map({ Highlight(x: Double(visitsChartDataSet.count - 1), dataSetIndex: 0, stackIndex: $0) }))

            for subview in visitsLegendStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for i in 0..<visitsToDisplayArray.count {
                let index = visitsToDisplayArray.count - i - 1
                let visitsEntry = visitsToDisplayArray[index]
                visitsLegendStackView.addArrangedSubview(LegendView(height: 13, color: gumroadStackedBarColors[index], name: visitsEntry.key, value: "(\(visitsEntry.value.reduce(0, +).withCommas()))"))
            }
            visitsLegendStackView.isHidden = false

            for subview in visitsHighlightedLegendStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for i in 0..<visitsToDisplayArray.count {
                let index = visitsToDisplayArray.count - i - 1
                let visitsEntry = visitsToDisplayArray[index]
                if let visitsValue = visitsEntry.value.last, visitsValue > 0 {
                    visitsHighlightedLegendStackView.addArrangedSubview(LegendView(height: 10, color: gumroadStackedBarColors[index], name: visitsEntry.key, value: "(\(visitsValue.withCommas()))"))
                }
            }
            visitsHighlightedLegendStackView.isHidden = false

            let visitsIsAllZero = visitsToDisplayArray.flatMap({ $0.value }).allSatisfy({ $0 == 0 })
            visitsNoDataView.isHidden = !visitsIsAllZero
            visitsHighlightedDateLabel.isHidden = visitsIsAllZero
            visitsBarChartView.isUserInteractionEnabled = !visitsIsAllZero
            visitsLoadingImageView.isHidden = true

            var salesDataEntries: [BarChartDataEntry] = []
            salesToDisplayArray = Array(salesToDisplayMap.filter({ $0.key != otherKey }).sorted(by: { $0.key.localizedCompare($1.key) == .orderedDescending }))
            if let otherElement = salesToDisplayMap.first(where: { $0.key == otherKey }) {
                salesToDisplayArray.insert(otherElement, at: 0)
            }
            // handle $0 values
            var allSalesTotals: [Double] = []
            for i in 0 ..< dateStrings.count {
                let sum = salesToDisplayArray.map({ Double($0.value[i]) }).reduce(0, +)
                if sum > 0 {
                    allSalesTotals.append(sum)
                }
            }
            let maxSalesTotalsValue = allSalesTotals.max() ?? 0
            let minSalesTotalsValue = allSalesTotals.min() ?? 0
            zeroSalesValue = min(minSalesTotalsValue, maxSalesTotalsValue / 75)
            while(true) {
                if allRevenueTotals.contains(zeroSalesValue) {
                    zeroSalesValue -= 0.01
                } else {
                    break
                }
            }
            for i in 0 ..< dateStrings.count {
                var yValues = salesToDisplayArray.map({ Double($0.value[i]) })
                if yValues.reduce(0, +) == 0 {
                    yValues = [Double](repeating: 0.0, count: yValues.count)
                    if yValues.isEmpty {
                        yValues = [zeroSalesValue]
                    } else {
                        yValues[0] = zeroSalesValue
                    }
                }
                salesDataEntries.append(BarChartDataEntry(x: Double(i), yValues: yValues, data: dateStrings[i]))
            }
            let salesChartDataSet = BarChartDataSet(entries: salesDataEntries)
            salesChartDataSet.colors = Array(gumroadStackedBarColors.map({ $0.withAlphaComponent(0.15) }).prefix(max(1, salesToDisplayArray.count)))
            salesChartDataSet.highlightEnabled = true
            salesChartDataSet.drawValuesEnabled = false
            let salesChartData = BarChartData(dataSet: salesChartDataSet)
            salesBarChartView.data = salesChartData
            (salesBarChartView.data as? BarChartData)?.barWidth = 0.714
            salesBarChartView.highlightValues((0..<salesToDisplayMap.count).map({ Highlight(x: Double(salesChartDataSet.count - 1), dataSetIndex: 0, stackIndex: $0) }))

            for subview in salesLegendStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for i in 0..<salesToDisplayArray.count {
                let index = salesToDisplayArray.count - i - 1
                let salesEntry = salesToDisplayArray[index]
                salesLegendStackView.addArrangedSubview(LegendView(height: 13, color: gumroadStackedBarColors[index], name: salesEntry.key, value: "(\(salesEntry.value.reduce(0, +).withCommas()))"))
            }
            salesLegendStackView.isHidden = false

            for subview in salesHighlightedLegendStackView.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for i in 0..<salesToDisplayArray.count {
                let index = salesToDisplayArray.count - i - 1
                let salesEntry = salesToDisplayArray[index]
                if let salesValue = salesEntry.value.last, salesValue > 0 {
                    salesHighlightedLegendStackView.addArrangedSubview(LegendView(height: 10, color: gumroadStackedBarColors[index], name: salesEntry.key, value: "(\(salesValue.withCommas()))"))
                }
            }
            salesHighlightedLegendStackView.isHidden = false

            let salesIsAllZero = salesToDisplayArray.flatMap({ $0.value }).allSatisfy({ $0 == 0 })
            salesNoDataView.isHidden = !salesIsAllZero
            salesHighlightedDateLabel.isHidden = salesIsAllZero
            salesBarChartView.isUserInteractionEnabled = !salesIsAllZero
            salesLoadingImageView.isHidden = true

            return
        }, failureBlock: { [self] (error) -> Void in
            revenueNoDataView.isHidden = false
            revenueHighlightedDateLabel.isHidden = true
            revenueBarChartView.isUserInteractionEnabled = false
            revenueLoadingImageView.isHidden = true
            visitsNoDataView.isHidden = false
            visitsHighlightedDateLabel.isHidden = true
            visitsBarChartView.isUserInteractionEnabled = false
            visitsLoadingImageView.isHidden = true
            salesNoDataView.isHidden = false
            salesHighlightedDateLabel.isHidden = true
            salesBarChartView.isUserInteractionEnabled = false
            salesLoadingImageView.isHidden = true

            return
        })
    }

    @IBAction func datetabButtonClicked(_ sender: UIButton) {
        if !sender.isSelected {
            for button in stackView.arrangedSubviews.compactMap({ $0 as? UIButton }) {
                if button != sender {
                    button.isSelected = false
                }
            }
            sender.isSelected = true
            revenueHighlightedDateLabel.text = nil
            visitsHighlightedDateLabel.text = nil
            salesHighlightedDateLabel.text = nil
            revenueBarChartView.data = nil
            revenueBarChartView.highlightValue(nil)
            visitsBarChartView.data = nil
            visitsBarChartView.highlightValue(nil)
            salesBarChartView.data = nil
            salesBarChartView.highlightValue(nil)

            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            updateData(with: DateRange.allCases[sender.tag])
        }
    }
}

extension TrafficViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        revenueHighlightedDateLabel.text = entry.data as? String
        visitsHighlightedDateLabel.text = entry.data as? String
        salesHighlightedDateLabel.text = entry.data as? String

        if !highlight.y.isNaN {
            revenueBarChartView.highlightValues((0..<revenueToDisplayMap.count).map({ Highlight(x: highlight.x, dataSetIndex: 0, stackIndex: $0) }))
            visitsBarChartView.highlightValues((0..<visitsToDisplayMap.count).map({ Highlight(x: highlight.x, dataSetIndex: 0, stackIndex: $0) }))
            salesBarChartView.highlightValues((0..<salesToDisplayMap.count).map({ Highlight(x: highlight.x, dataSetIndex: 0, stackIndex: $0) }))
        }

        for subview in revenueHighlightedLegendStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for i in 0..<revenueToDisplayArray.count {
            let index = revenueToDisplayArray.count - i - 1
            let revenueEntry = revenueToDisplayArray[index]
            if let revenueValue = revenueEntry.value[safe: Int(highlight.x)], revenueValue > 0 {
            revenueHighlightedLegendStackView.addArrangedSubview(LegendView(height: 10, color: gumroadStackedBarColors[index], name: revenueEntry.key, value: "(\((Double(revenueValue) / 100).dollarFormat()))"))
            }
        }
        revenueHighlightedLegendStackView.isHidden = false

        for subview in visitsHighlightedLegendStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for i in 0..<visitsToDisplayArray.count {
            let index = visitsToDisplayArray.count - i - 1
            let visitsEntry = visitsToDisplayArray[index]
            if let visitsValue = visitsEntry.value[safe: Int(highlight.x)], visitsValue > 0 {
                visitsHighlightedLegendStackView.addArrangedSubview(LegendView(height: 10, color: gumroadStackedBarColors[index], name: visitsEntry.key, value: "(\(visitsValue.withCommas()))"))
            }
        }

        for subview in salesHighlightedLegendStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for i in 0..<salesToDisplayArray.count {
            let index = salesToDisplayArray.count - i - 1
            let salesEntry = salesToDisplayArray[index]
            if let salesValue = salesEntry.value[safe: Int(highlight.x)], salesValue > 0 {
                salesHighlightedLegendStackView.addArrangedSubview(LegendView(height: 10, color: gumroadStackedBarColors[index], name: salesEntry.key, value: "(\(salesValue.withCommas()))"))
            }
        }
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        revenueHighlightedDateLabel.text = nil
        visitsHighlightedDateLabel.text = nil
        salesHighlightedDateLabel.text = nil

        revenueBarChartView.highlightValue(nil)
        visitsBarChartView.highlightValue(nil)
        salesBarChartView.highlightValue(nil)
    }

//    func chartViewDidBeginPanning(_ chartView: ChartViewBase) {
//        scrollView.isScrollEnabled = false
//    }
//
//    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
//        scrollView.isScrollEnabled = true
//    }
}

class LegendView: UIView {
    convenience init(height: CGFloat, color: UIColor, name: String, value: String) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false

        let circleView = UIView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = color
        let maskShape = CAShapeLayer()
        let bezierPathMask = UIBezierPath()
        bezierPathMask.move(to: CGPoint(x: height, y: height))
        bezierPathMask.addArc(withCenter: CGPoint(x: height / 2, y: height / 2), radius: height / 2, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        bezierPathMask.close()
        maskShape.path = bezierPathMask.cgPath

        circleView.layer.mask = maskShape
        circleView.isHidden = false

        addSubview(circleView)
        circleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        circleView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: height).isActive = true
        circleView.widthAnchor.constraint(equalToConstant: height).isActive = true

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = UIFont(name: "Mabry Pro", size: height)
        nameLabel.textColor = UIColor(named: "GumroadLabelColor")

        addSubview(nameLabel)
        nameLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: circleView.trailingAnchor, constant: 5).isActive = true

        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont(name: "Mabry Pro", size: height)
        valueLabel.textColor = UIColor(named: "GumroadLabelColor")

        addSubview(valueLabel)
        valueLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor).isActive = true
        valueLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 3).isActive = true

        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
