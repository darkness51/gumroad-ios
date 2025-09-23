//
//  SalesViewController.swift
//  iOSCreator
//
//  Created by Nathan Chan on 7/13/21.
//  Copyright © 2021 GRD. All rights reserved.
//

import UIKit
import Charts

class SalesViewController: UIViewController, StoryboardIdentifiable {
    static var storyboardName: StoryboardName = .creator

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var salesRevenueHighlightedDateLabel: UILabel!
    @IBOutlet weak var salesRevenueLabel: UILabel!
    @IBOutlet weak var salesRevenueHighlightedLabel: UILabel!
    @IBOutlet weak var salesRevenueBarChartView: BarChartView!
    @IBOutlet weak var salesRevenueNoDataView: UIView!
    @IBOutlet weak var salesRevenueLoadingImageView: UIImageView!
    @IBOutlet weak var salesHighlightedDateLabel: UILabel!
    @IBOutlet weak var salesLabel: UILabel!
    @IBOutlet weak var salesHighlightedLabel: UILabel!
    @IBOutlet weak var salesBarChartView: BarChartView!
    @IBOutlet weak var salesNoDataView: UIView!
    @IBOutlet weak var salesLoadingImageView: UIImageView!
    @IBOutlet weak var viewsHighlightedDateLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var viewsHighlightedLabel: UILabel!
    @IBOutlet weak var viewsBarChartView: BarChartView!
    @IBOutlet weak var viewsNoDataView: UIView!
    @IBOutlet weak var viewsLoadingImageView: UIImageView!

    let pulseAnimation = CABasicAnimation(keyPath: "opacity")
    let pulseAnimationKey = "pulseAnimation"

    let salesRevenueBarChartViewName = "salesRevenueBarChartView"
    let salesBarChartViewName = "salesBarChartView"
    let viewsBarChartViewName = "viewsBarChartView"

    var zeroTotalsValue: Double = 0
    var zeroSalesValue: Double = 0
    var zeroViewsValue: Double = 0

    var lastDateRangeFetched = DateRange.week

    override func viewDidLoad() {
        super.viewDidLoad()

        salesRevenueBarChartView.delegate = self
        salesRevenueBarChartView.accessibilityLabel = salesRevenueBarChartViewName
        salesRevenueBarChartView.xAxis.enabled = true
        salesRevenueBarChartView.xAxis.axisLineColor = UIColor(named: "GumroadBorderColor")!
        salesRevenueBarChartView.xAxis.axisLineWidth = 1
        salesRevenueBarChartView.xAxis.labelPosition = .bottom
        salesRevenueBarChartView.xAxis.drawLabelsEnabled = false
        salesRevenueBarChartView.xAxis.drawAxisLineEnabled = true
        salesRevenueBarChartView.xAxis.drawGridLinesEnabled = false
        salesRevenueBarChartView.leftAxis.enabled = false
        salesRevenueBarChartView.leftAxis.axisMinimum = 0
        salesRevenueBarChartView.rightAxis.enabled = false
        salesRevenueBarChartView.drawGridBackgroundEnabled = false
        salesRevenueBarChartView.pinchZoomEnabled = false
        salesRevenueBarChartView.doubleTapToZoomEnabled = false
        salesRevenueBarChartView.legend.enabled = false
//        salesRevenueBarChartView.dragEnabled = false

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

        viewsBarChartView.delegate = self
        viewsBarChartView.accessibilityLabel = viewsBarChartViewName
        viewsBarChartView.xAxis.enabled = true
        viewsBarChartView.xAxis.axisLineColor = UIColor(named: "GumroadBorderColor")!
        viewsBarChartView.xAxis.axisLineWidth = 1
        viewsBarChartView.xAxis.labelPosition = .bottom
        viewsBarChartView.xAxis.drawLabelsEnabled = false
        viewsBarChartView.xAxis.drawAxisLineEnabled = true
        viewsBarChartView.xAxis.drawGridLinesEnabled = false
        viewsBarChartView.leftAxis.enabled = false
        viewsBarChartView.leftAxis.axisMinimum = 0
        viewsBarChartView.rightAxis.enabled = false
        viewsBarChartView.drawGridBackgroundEnabled = false
        viewsBarChartView.pinchZoomEnabled = false
        viewsBarChartView.doubleTapToZoomEnabled = false
        viewsBarChartView.legend.enabled = false
//        viewsBarChartView.dragEnabled = false

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
        salesRevenueLoadingImageView.image = UIImage(named: "loading-\(dateRange.rawValue)")
        salesRevenueLoadingImageView.layer.add(pulseAnimation, forKey: pulseAnimationKey)
        salesRevenueNoDataView.isHidden = true
        salesRevenueLoadingImageView.isHidden = false
        salesLoadingImageView.image = UIImage(named: "loading-\(dateRange.rawValue)")
        salesLoadingImageView.layer.add(pulseAnimation, forKey: pulseAnimationKey)
        salesNoDataView.isHidden = true
        salesLoadingImageView.isHidden = false
        viewsLoadingImageView.image = UIImage(named: "loading-\(dateRange.rawValue)")
        viewsLoadingImageView.layer.add(pulseAnimation, forKey: pulseAnimationKey)
        viewsNoDataView.isHidden = true
        viewsLoadingImageView.isHidden = false

        lastDateRangeFetched = dateRange

        GRDNetworkRequest.shared.fetchAnalyticsByDate(dateRange, successBlock: { [self] (response, responseObject) -> Void in
            if lastDateRangeFetched != dateRange { return }

            guard let data = responseObject as? [String: Any] else { return }
            guard let dateStrings = data["dates"] as? [String] else { return }
            guard let byDateMap = (data["by_date"]) as? [String: Any] else { return }
            guard let totalsMap = byDateMap["totals"] as? [String: Any] else { return }
            guard let salesMap = byDateMap["sales"] as? [String: Any] else { return }
            guard let viewsMap = byDateMap["views"] as? [String: Any] else { return }
            let totalsArray = Array(totalsMap.values).compactMap({ $0 as? [Double] })
            let salesArray = Array(salesMap.values).compactMap({ $0 as? [Double] })
            let viewsArray = Array(viewsMap.values).compactMap({ $0 as? [Double] })
            var totalsByDate: [(Double, String)] = []
            var salesByDate: [(Double, String)] = []
            var viewsByDate: [(Double, String)] = []
            for i in 0 ..< dateStrings.count {
                var totalForProduct: Double = 0
                var salesForProduct: Double = 0
                var viewsForProduct: Double = 0
                for j in 0 ..< totalsArray.count {
                    totalForProduct += totalsArray[safe: j]?[safe: i] ?? 0
                    salesForProduct += salesArray[safe: j]?[safe: i] ?? 0
                    viewsForProduct += viewsArray[safe: j]?[safe: i] ?? 0
                }
                totalsByDate.append((totalForProduct / 100, dateStrings[safe: i] ?? ""))
                salesByDate.append((salesForProduct, dateStrings[safe: i] ?? ""))
                viewsByDate.append((viewsForProduct, dateStrings[safe: i] ?? ""))
            }

            // handle $0 values
            let allPositiveTotalsValues = Set(totalsByDate.map({ $0.0 }).filter({ $0 > 0 }))
            let maxTotalsValue = allPositiveTotalsValues.max() ?? 0
            let minTotalsValue = allPositiveTotalsValues.min() ?? 0
            zeroTotalsValue = min(minTotalsValue, maxTotalsValue / 75)
            while(true) {
                if allPositiveTotalsValues.contains(zeroTotalsValue) {
                    zeroTotalsValue -= 0.01
                } else {
                    break
                }
            }
            for i in 0 ..< totalsByDate.count {
                if totalsByDate[i].0 == 0 {
                    totalsByDate[i].0 = zeroTotalsValue
                }
            }

            let allPositiveSalesValues = Set(salesByDate.map({ $0.0 }).filter({ $0 > 0 }))
            let maxSalesValue = allPositiveSalesValues.max() ?? 0
            let minSalesValue = allPositiveSalesValues.min() ?? 0
            zeroSalesValue = min(minSalesValue, maxSalesValue / 75)
            while(true) {
                if allPositiveSalesValues.contains(zeroSalesValue) {
                    zeroSalesValue -= 0.01
                } else {
                    break
                }
            }
            for i in 0 ..< salesByDate.count {
                if salesByDate[i].0 == 0 {
                    salesByDate[i].0 = zeroSalesValue
                }
            }

            let allPositiveViewsValues = Set(viewsByDate.map({ $0.0 }).filter({ $0 > 0 }))
            let maxViewsValue = allPositiveViewsValues.max() ?? 0
            let minViewsValue = allPositiveViewsValues.min() ?? 0
            zeroViewsValue = min(minViewsValue, maxViewsValue / 75)
            while(true) {
                if allPositiveViewsValues.contains(zeroViewsValue) {
                    zeroViewsValue -= 0.01
                } else {
                    break
                }
            }
            for i in 0 ..< viewsByDate.count {
                if viewsByDate[i].0 == 0 {
                    viewsByDate[i].0 = zeroViewsValue
                }
            }

            let salesRevenueTotal = totalsByDate.map({ $0.0 }).filter({ $0 != zeroTotalsValue }).reduce(0, +)
            salesRevenueLabel.text = salesRevenueTotal.dollarFormat()

            salesLabel.text = "\(salesByDate.filter({ $0.0 != zeroSalesValue }).map({ Int($0.0) }).reduce(0, +).withCommas())"

            viewsLabel.text = "\(viewsByDate.filter({ $0.0 != zeroViewsValue }).map({ Int($0.0) }).reduce(0, +).withCommas())"

            var totalsDataEntries: [BarChartDataEntry] = []
            for i in 0 ..< totalsByDate.count {
                totalsDataEntries.append(BarChartDataEntry(x: Double(i), y: Double(totalsByDate[i].0), data: totalsByDate[i].1))
            }
            let totalsChartDataSet = BarChartDataSet(entries: totalsDataEntries)
            totalsChartDataSet.colors = totalsDataEntries.map({ _ in UIColor(named: "GumroadLabelColor")!.withAlphaComponent(0.15)
            })
            totalsChartDataSet.highlightEnabled = true
            totalsChartDataSet.drawValuesEnabled = false
            let totalsChartData = BarChartData(dataSet: totalsChartDataSet)
            salesRevenueBarChartView.data = totalsChartData
            (salesRevenueBarChartView.data as? BarChartData)?.barWidth = 0.714
            salesRevenueBarChartView.highlightValue(x: Double(totalsChartDataSet.count - 1), dataSetIndex: 0)
            let totalsIsAllZero = totalsByDate.map({ $0.0 }).allSatisfy({ $0 == 0 })
            salesRevenueNoDataView.isHidden = !totalsIsAllZero
            salesRevenueHighlightedDateLabel.isHidden = totalsIsAllZero
            salesRevenueBarChartView.isUserInteractionEnabled = !totalsIsAllZero
            salesRevenueLoadingImageView.isHidden = true

            var salesDataEntries: [BarChartDataEntry] = []
            for i in 0 ..< salesByDate.count {
                salesDataEntries.append(BarChartDataEntry(x: Double(i), y: Double(salesByDate[i].0), data: salesByDate[i].1))
            }
            let salesChartDataSet = BarChartDataSet(entries: salesDataEntries)
            salesChartDataSet.colors = salesDataEntries.map({ _ in UIColor(named: "GumroadLabelColor")!.withAlphaComponent(0.15)
            })
            salesChartDataSet.highlightEnabled = true
            salesChartDataSet.drawValuesEnabled = false
            let salesChartData = BarChartData(dataSet: salesChartDataSet)
            salesBarChartView.data = salesChartData
            (salesBarChartView.data as? BarChartData)?.barWidth = 0.714
            salesBarChartView.highlightValue(x: Double(salesChartDataSet.count - 1), dataSetIndex: 0)
            let salesIsAllZero = salesByDate.map({ $0.0 }).allSatisfy({ $0 == 0 })
            salesNoDataView.isHidden = !salesIsAllZero
            salesHighlightedDateLabel.isHidden = salesIsAllZero
            salesBarChartView.isUserInteractionEnabled = !salesIsAllZero
            salesLoadingImageView.isHidden = true

            var viewsDataEntries: [BarChartDataEntry] = []
            for i in 0 ..< viewsByDate.count {
                viewsDataEntries.append(BarChartDataEntry(x: Double(i), y: Double(viewsByDate[i].0), data: viewsByDate[i].1))
            }
            let viewsChartDataSet = BarChartDataSet(entries: viewsDataEntries)
            viewsChartDataSet.colors = viewsDataEntries.map({ _ in UIColor(named: "GumroadLabelColor")!.withAlphaComponent(0.15)
            })
            viewsChartDataSet.highlightEnabled = true
            viewsChartDataSet.drawValuesEnabled = false
            let viewsChartData = BarChartData(dataSet: viewsChartDataSet)
            viewsBarChartView.data = viewsChartData
            (viewsBarChartView.data as? BarChartData)?.barWidth = 0.714
            viewsBarChartView.highlightValue(x: Double(viewsChartDataSet.count - 1), dataSetIndex: 0)
            let viewsIsAllZero = viewsByDate.map({ $0.0 }).allSatisfy({ $0 == 0 })
            viewsNoDataView.isHidden = !viewsIsAllZero
            viewsHighlightedDateLabel.isHidden = viewsIsAllZero
            viewsBarChartView.isUserInteractionEnabled = !viewsIsAllZero
            viewsLoadingImageView.isHidden = true

            return
        }, failureBlock: { [self] (error) -> Void in
            salesRevenueNoDataView.isHidden = false
            salesRevenueHighlightedDateLabel.isHidden = true
            salesRevenueBarChartView.isUserInteractionEnabled = false
            salesRevenueLoadingImageView.isHidden = true
            salesNoDataView.isHidden = false
            salesHighlightedDateLabel.isHidden = true
            salesBarChartView.isUserInteractionEnabled = false
            salesLoadingImageView.isHidden = true
            viewsNoDataView.isHidden = false
            viewsHighlightedDateLabel.isHidden = true
            viewsBarChartView.isUserInteractionEnabled = false
            viewsLoadingImageView.isHidden = true

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
            salesRevenueLabel.text = nil
            salesRevenueBarChartView.data = nil
            salesRevenueBarChartView.highlightValue(nil)
            salesRevenueHighlightedLabel.text = nil
            salesRevenueHighlightedDateLabel.text = nil
            salesLabel.text = nil
            salesBarChartView.data = nil
            salesBarChartView.highlightValue(nil)
            salesHighlightedLabel.text = nil
            salesHighlightedDateLabel.text = nil
            viewsLabel.text = nil
            viewsBarChartView.data = nil
            viewsBarChartView.highlightValue(nil)
            viewsHighlightedLabel.text = nil
            viewsHighlightedDateLabel.text = nil
            
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            updateData(with: DateRange.allCases[sender.tag])
        }
    }
}

extension SalesViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        salesRevenueHighlightedDateLabel.text = entry.data as? String
        salesHighlightedDateLabel.text = entry.data as? String
        viewsHighlightedDateLabel.text = entry.data as? String

        if !highlight.y.isNaN {
            salesRevenueBarChartView.highlightValue(x: highlight.x, dataSetIndex: 0)
            salesBarChartView.highlightValue(x: highlight.x, dataSetIndex: 0)
            viewsBarChartView.highlightValue(x: highlight.x, dataSetIndex: 0)
        }

        switch chartView.accessibilityLabel {
        case salesRevenueBarChartViewName:
            let salesRevenueTotal = zeroTotalsValue == entry.y ? 0 : entry.y
            salesRevenueHighlightedLabel.text = salesRevenueTotal.dollarFormat()
        case salesBarChartViewName:
            salesHighlightedLabel.text = Int(zeroSalesValue == entry.y ? 0 : entry.y).withCommas() + " sales"
        case viewsBarChartViewName:
            viewsHighlightedLabel.text = Int(zeroViewsValue == entry.y ? 0 : entry.y).withCommas() + " views"
        default:
            break
        }
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        salesRevenueHighlightedDateLabel.text = nil
        salesHighlightedDateLabel.text = nil
        viewsHighlightedDateLabel.text = nil
        salesRevenueHighlightedLabel.text = nil
        salesHighlightedLabel.text = nil
        viewsHighlightedLabel.text = nil

        salesRevenueBarChartView.highlightValue(nil)
        salesBarChartView.highlightValue(nil)
        viewsBarChartView.highlightValue(nil)
    }

//    func chartViewDidBeginPanning(_ chartView: ChartViewBase) {
//        scrollView.isScrollEnabled = false
//    }
//
//    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
//        scrollView.isScrollEnabled = true
//    }
}
