//
//  CHDepthChartView.swift
//  CHKLineChart
//
//  Created by Chance on 2017/6/26.
//  Copyright © 2017年 bitbank. All rights reserved.
//

import UIKit


/// 深度数据项类型
///
/// - bid: 买方深度
/// - ask: 卖方深度
public enum CHKDepthChartItemType {
    case bid
    case ask
}

/**
 *  深度数据元素
 */
open class CHKDepthChartItem: NSObject {
    
    open var value: CGFloat = 0                              //数值
    open var amount: CGFloat = 0                             //数量
    open var depthAmount: CGFloat = 0                        //计算得到的深度
    open var type: CHKDepthChartItemType = .bid               //数据类型

}

/**
 *  深度图表数据源代理
 */
@objc public protocol CHKDepthChartDelegate: class {
    
    /**
     数据源总数
     
     - parameter chart:
     
     - returns:
     */
    func numberOfPointsInDepthChart(chart: CHDepthChartView) -> Int
    
    /**
     数据源索引为对应的对象
     
     - parameter chart:
     - parameter index: 索引位
     
     - returns: K线数据对象
     */
    func depthChart(chart: CHDepthChartView, valueForPointAtIndex index: Int) -> CHKDepthChartItem
    
    /**
     获取图表Y轴的显示的内容
     
     - parameter chart:
     - parameter value:     计算得出的y值
     
     - returns:
     */
    @objc func depthChart(chart: CHDepthChartView, labelOnYAxisForValue value: CGFloat) -> String
    
    
    /// y轴的显示的基底值
    /// 用户可以自定义y轴的标签什么数值显示，通过配合实现incrementValueForYAxis的方法，
    /// 做到更好的用户体验，例如：baseValue = 0，incrementValue = 10，则显示y轴显示为0，10，20，30，40...<max
    /// - Parameter depthChart: 图表
    /// - Returns: 开始显示的值
    @objc optional func baseValueForYAxisInDepthChart(in depthChart: CHDepthChartView) -> Double
    
    
    /// y轴每段增加的值
    /// 例如：baseValue = 0，incrementValue = 10，则显示y轴显示为0，10，20，30，40...<max
    /// - Parameter depthChart: 图表
    /// - Returns: 增量
    @objc optional func incrementValueForYAxisInDepthChart(in depthChart: CHDepthChartView) -> Double
    
    /**
     获取图表X轴的显示的内容
     
     - parameter chart:
     - parameter index:     索引位
     
     - returns:
     */
    @objc optional func depthChart(chart: CHDepthChartView, labelOnXAxisForIndex index: Int) -> String
    
    /**
     完成绘画图表
     
     */
    @objc optional func didFinishDepthChartRefresh(chart: CHDepthChartView)
    
    /// 设置y轴标签的宽度
    ///
    /// - parameter chart:
    ///
    /// - returns:
    @objc optional func widthForYAxisLabelInDepthChart(in depthChart: CHDepthChartView) -> CGFloat
    
    
    /// 点击图表列响应方法
    ///
    /// - Parameters:
    ///   - chart: 图表
    ///   - index: 点击的位置
    ///   - item: 数据对象
    @objc optional func depthChart(chart: CHDepthChartView, didSelectAt index: Int, item: CHChartItem)
    
    
    /// X轴的布局高度
    ///
    /// - Parameter chart: 图表
    /// - Returns: 返回自定义的高度
    @objc optional func heightForXAxisInDepthChart(in depthChart: CHDepthChartView) -> CGFloat
}

open class CHDepthChartView: UIView {

    /// MARK: - 常量
    open let kYAxisLabelWidth: CGFloat = 46        //默认宽度
    open let kXAxisHegiht: CGFloat = 16        //默认X坐标的高度
    
    /// MARK: - 成员变量
    open var bidColor: (stroke: UIColor, fill: UIColor, lineWidth: CGFloat) = (.green, .green, 1)
    open var askColor: (stroke: UIColor, fill: UIColor, lineWidth: CGFloat) = (.red, .red, 1)
    @IBInspectable open var labelFont = UIFont.systemFont(ofSize: 10)
    @IBInspectable open var lineColor: UIColor = UIColor(white: 0.2, alpha: 1) //线条颜色
    @IBInspectable open var textColor: UIColor = UIColor(white: 0.8, alpha: 1) //文字颜色
    @IBInspectable open var xAxisPerInterval: Int = 4                        //x轴的间断个数
    
    open var yAxis: CHYAxis = CHYAxis()                           //Y轴参数
    open var xAxis: CHXAxis = CHXAxis()                             //X轴参数
    open var yAxisLabelWidth: CGFloat = 0                    //Y轴的宽度
    open var decimal: Int = 2                                        //小数位的长度
    open var padding: UIEdgeInsets = UIEdgeInsets.zero    //内边距
    open var showYAxisLabel = CHYAxisShowPosition.right      //显示y的位置，默认右边
    open var isInnerYAxis: Bool = false                     // 是否把y坐标内嵌到图表仲
    /// 是否显示X轴标签
    open var showXAxisLabel: Bool = true
    
    @IBOutlet open weak var delegate: CHKDepthChartDelegate?             //代理
    
    open var selectedIndex: Int = -1                      //选择索引位
    var selectedPoint: CGPoint = CGPoint.zero
    
    //是否可点选
    open var enableTap: Bool = true

    /// 显示边线上左下有
    open var borderWidth: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) = (0.25, 0.25, 0.25, 0.25)
    
    var lineWidth: CGFloat = 0.5
    var plotCount: Int = 0

    open var labelSize = CGSize(width: 40, height: 16)
    
    open var selectedBGColor: UIColor = UIColor(white: 0.4, alpha: 1)    //选中点的显示的框背景颜色
    open var selectedTextColor: UIColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1) //选中点的显示的文字颜色

    //每个点的间隔宽度
    var plotWidth: CGFloat {
        if self.plotCount > 0 {
            return (self.bounds.size.width - self.padding.left - self.padding.right) / CGFloat(self.plotCount)
        } else {
            return 0
        }
    }
    
    /// 买方深度数据
    open var bidItems = [CHKDepthChartItem]()
    
    /// 卖方深度数据
    open var askItems = [CHKDepthChartItem]()
    
    /// 用于图表的图层
    var drawLayer: CHShapeLayer = CHShapeLayer()
    
    /// 买方深度图层
    var bidsLayer: CHShapeLayer = CHShapeLayer()
    
    /// 卖方深度图层
    var asksLayer: CHShapeLayer = CHShapeLayer()
    
    open var style: CHKLineChartStyle! {           //显示样式
        didSet {
            //重新配置样式
            self.backgroundColor = self.style.backgroundColor
            self.padding = self.style.padding
            self.lineColor = self.style.lineColor
            self.textColor = self.style.textColor
            self.labelFont = self.style.labelFont
            self.showYAxisLabel = self.style.showYAxisLabel
            self.selectedBGColor = self.style.selectedBGColor
            self.selectedTextColor = self.style.selectedTextColor
            self.isInnerYAxis = self.style.isInnerYAxis
            self.enableTap = self.style.enableTap
            self.showXAxisLabel = self.style.showXAxisLabel
            self.borderWidth = self.style.borderWidth
            self.bidColor = self.style.bidColor
            self.askColor = self.style.askColor
        }
        
    }
    
    
    
    // MARK: - 初始化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //self.initUI()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.initUI()
    }

    
    /**
     初始化UI
     
     - returns:
     */
    fileprivate func initUI() {
        
        //绘画图层
        self.layer.addSublayer(self.drawLayer)
        
        
        //点击手势操作
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(doTapAction(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
        
        //初始数据
        self.resetData()
        
    }
    
    //MARK: - 内部方法
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        //布局完成重绘
        self.drawLayerView()
    }
    
    /**
     初始化数据
     */
    fileprivate func resetData() {
        self.bidItems.removeAll()
        self.askItems.removeAll()
        self.plotCount = self.delegate?.numberOfPointsInDepthChart(chart: self) ?? 0
        
        if plotCount > 0 {
            
            //获取代理上的数据源
            for i in 0...self.plotCount - 1 {
                guard let item = self.delegate?.depthChart(chart: self, valueForPointAtIndex: i) else {
                    continue
                }
                switch item.type {
                case .bid:
                    self.bidItems.append(item)
                case .ask:
                    self.askItems.append(item)
                }
            }
            
            //计算深度数量
            self.computeDepthValue(for: self.bidItems, type: .bid)
            self.computeDepthValue(for: self.askItems, type: .ask)
            
        }
    }
    
    
    /// 根据数据集合计算出每个元素的深度
    ///
    /// - Parameter item: 数据集合
    fileprivate func computeDepthValue(for items: [CHKDepthChartItem], type: CHKDepthChartItemType) {
        
        var depth: CGFloat = 0
        var start = 0, end = 0, step = 1
        if type == .bid {
            //买单深度是由价格大到小地累计
            start = items.count - 1
            end = 0
            step = -1
        } else {
            //卖单深度是由价格大到小地累计
            start = 0
            end = items.count - 1
            step = 1
        }
        
        for i in stride(from: start, through: end, by: step) {
            let item = items[i]
            let amount = item.amount
            depth = depth + amount
            item.depthAmount = depth
            
        }
    }
    
    
    /**
     设置选中的数据点
     
     - parameter point:
     */
    func setSelectedIndexByPoint(_ point: CGPoint) {
        
        
        guard self.enableTap else {
            return
        }
        
        guard self.plotCount > 0 else {
            return
        }
        
        if point.equalTo(CGPoint.zero) {
            return
        }
        
        
//        let format = "%.".appendingFormat("%df", yaxis.decimal)
        
        self.selectedPoint = point
        
        //每个点的间隔宽度
//        let plotWidth = (self.bounds.size.width - self.padding.left - self.padding.right) / CGFloat(self.plotCount)
        
//        let yVal = section!.getRawValue(point.y)        //获取y轴坐标的实际值
        
//        for i in self.plotCount - 1 {
//            let ixs = plotWidth * CGFloat(i - self.rangeFrom) + section!.padding.left + self.padding.left
//            let ixe = plotWidth * CGFloat(i - self.rangeFrom + 1) + section!.padding.left + self.padding.left
//           
//            if ixs <= point.x && point.x < ixe {
//                self.selectedIndex = i
//                let item = self.datas[i]
//                
//                //回调给代理委托方法
//                self.delegate?.kLineChart?(chart: self, didSelectAt: i, item: item)
//                
//                break
//            }
            
//        }
    }
    
    /**
     获取y轴上标签数值对应在坐标系中的y值
     
     - parameter val: 标签值
     
     - returns: 坐标系中实际的y值
     */
    func getLocalY(_ val: CGFloat) -> CGFloat {
        let max = self.yAxis.max
        let min = self.yAxis.min
        
        if (max == min) {
            return 0
        }
        
        /*
         计算公式：
         y轴有值的区间高度 = 整个分区高度-（paddingTop+paddingBottom）
         当前y值所在位置的比例 =（当前值 - y最小值）/（y最大值 - y最小值）
         当前y值的实际的相对y轴有值的区间的高度 = 当前y值所在位置的比例 * y轴有值的区间高度
         当前y值的实际坐标 = 分区高度 + 分区y坐标 - paddingBottom - 当前y值的实际的相对y轴有值的区间的高度
         */
        let baseY = self.bounds.maxY - self.padding.bottom - (self.bounds.size.height - self.padding.top - self.padding.bottom) * (val - min) / (max - min)
//        NSLog("baseY(val) = \(baseY)(\(val))")
//        NSLog("fra.size.height = \(self.bounds.size.height)");
//        NSLog("self.bounds.maxY = \(self.bounds.maxY)");
//        NSLog("max = \(max)");
//        NSLog("min = \(min)");
        return baseY
    }
    
    /**
     获取坐标系中y坐标对应的y值
     
     - parameter y:
     
     - returns:
     */
    func getRawValue(_ y: CGFloat) -> CGFloat {
        let max = self.yAxis.max
        let min = self.yAxis.min
        
        let ymax = self.getLocalY(self.yAxis.min)       //y最大值对应y轴上的最高点，则最小值
        let ymin = self.getLocalY(self.yAxis.max)       //y最小值对应y轴上的最低点，则最大值
        
        if (max == min) {
            return 0
        }
        
        let value = (y - ymax) / (ymin - ymax) * (max - min) + min
        
        return value
    }
    
}

// MARK: - 绘图相关方法
extension CHDepthChartView {
    
    
    /// 清空图表的子图层
    func removeLayerView() {
        _ = self.drawLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.drawLayer.sublayers?.removeAll()
        _ = self.bidsLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.bidsLayer.sublayers?.removeAll()
        _ = self.asksLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.asksLayer.sublayers?.removeAll()
    }
    
    /// 通过CALayer方式画图表
    func drawLayerView() {
        
        //先清空图层
        self.removeLayerView()
        
        
        /// 待绘制的x坐标标签
//        var xAxisToDraw = [(CGRect, String)]()
        
        //绘制图表框架
        self.drawChartFrame()
        
        //初始Y轴的数据
        self.initXYAxis()
        
        //绘制Y轴坐标系，但最后的y轴标签放到绘制完线段才做
        let yAxisToDraw = self.drawYAxis()
        
        //绘制X轴坐标系，先绘制辅助线，记录标签位置，
        //返回出来，最后才在需要显示的分区上绘制
//        xAxisToDraw = self.drawXAxis(section)
        
        //绘制图表的点线
        self.drawChart()
        
        //绘制Y轴坐标上的标签
        self.drawYAxisLabel(yAxisToDraw)
        
        //显示在分区下面绘制X轴坐标
//        self.drawXAxisLabel(showXAxisSection, xAxisToDraw: xAxisToDraw)
        
        //重新显示点击选中的坐标
//        self.setSelectedIndexByPoint(self.selectedPoint)
        
        self.delegate?.didFinishDepthChartRefresh?(chart: self)
        
    }

    
    /**
     绘制图表框
     
     - returns: 是否初始化数据
     */
    fileprivate func drawChartFrame() {
        
        let backgroundLayer = CHShapeLayer()
        let backgroundPath = UIBezierPath(rect: self.bounds)
        backgroundLayer.path = backgroundPath.cgPath
        backgroundLayer.fillColor = self.backgroundColor?.cgColor
        self.drawLayer.addSublayer(backgroundLayer)
        
        self.yAxisLabelWidth = self.delegate?.widthForYAxisLabelInDepthChart?(in: self) ?? self.kYAxisLabelWidth
        
        //y轴的标签显示方位
        switch self.showYAxisLabel {
        case .left:         //左边显示
            self.padding.left = self.isInnerYAxis ? self.padding.left : self.yAxisLabelWidth
            self.padding.right = 0
        case .right:        //右边显示
            self.padding.left = 0
            self.padding.right = self.isInnerYAxis ? self.padding.right : self.yAxisLabelWidth
        case .none:         //都不显示
            self.padding.left = 0
            self.padding.right = 0
        }
        
        let borderPath = UIBezierPath()
        
        //画低部边线
        if self.borderWidth.bottom > 0 {
            
            borderPath.append(UIBezierPath(rect: CGRect(x: self.bounds.origin.x + self.padding.left, y: self.bounds.size.height + self.bounds.origin.y, width: self.bounds.size.width - self.padding.left, height: self.borderWidth.bottom)))
            
        }
        
        //画顶部边线
        if self.borderWidth.top > 0 {
            
            borderPath.append(UIBezierPath(rect: CGRect(x: self.bounds.origin.x + self.padding.left, y: self.bounds.origin.y, width: self.bounds.size.width - self.padding.left, height: self.borderWidth.top)))
            
        }
        
        
        //画左边线
        if self.borderWidth.left > 0 {
            
            borderPath.append(UIBezierPath(rect: CGRect(x: self.bounds.origin.x + self.padding.left, y: self.bounds.origin.y, width: self.borderWidth.left, height: self.bounds.size.height)))
            
        }
        
        
        //画右边线
        if self.borderWidth.right > 0 {
            
            borderPath.append(UIBezierPath(rect: CGRect(x: self.bounds.origin.x + self.bounds.size.width - self.padding.right, y: self.bounds.origin.y, width: self.borderWidth.left, height: self.bounds.size.height)))
            
        }
        
        //添加到图层
        let borderLayer = CHShapeLayer()
        borderLayer.lineWidth = self.lineWidth
        borderLayer.path = borderPath.cgPath  // 从贝塞尔曲线获取到形状
        borderLayer.fillColor = self.lineColor.cgColor // 闭环填充的颜色
        self.drawLayer.addSublayer(borderLayer)
        

    }

    
    /**
     初始化分区上XY轴的数值
     */
    fileprivate func initXYAxis() {
        
        //添加深度数据
        var datas = [CHKDepthChartItem]()
        datas.append(contentsOf: self.bidItems)
        datas.append(contentsOf: self.askItems)
        
        guard datas.count > 0 else {
            return  //没有数据返回
        }
        
        //计算y轴最大最小值
        //计算x轴最大最小值
        self.yAxis.decimal = self.decimal
        self.yAxis.max = 0
        self.yAxis.min = CGFloat.greatestFiniteMagnitude
        
        
        //计算最小最大值
        for item in datas {
            
            //判断数据集合的每个价格，把最大值和最少设置到y轴对象中
            if item.depthAmount > self.yAxis.max {
                self.yAxis.max = item.depthAmount
            }
            if item.depthAmount < self.yAxis.min {
                self.yAxis.min = item.depthAmount
            }
        }
        
        //如果有基础值
        guard let baseValue = self.delegate?.baseValueForYAxisInDepthChart?(in: self) else {
            return
        }
        
        self.yAxis.baseValue = CGFloat(baseValue)
        if self.yAxis.baseValue < self.yAxis.min {
            self.yAxis.min = self.yAxis.baseValue
        }
        
        if self.yAxis.baseValue > self.yAxis.max {
            self.yAxis.max = self.yAxis.baseValue
        }
        
    }
    
    
    
    /**
     绘制Y轴左边
     
     - parameter section: 分区
     */
    fileprivate func drawYAxis() -> [(CGRect, String)] {
        
        var yAxisToDraw = [(CGRect, String)]()
        var valueToDraw = Set<CGFloat>()
        
        var startX: CGFloat = 0, startY: CGFloat = 0, extrude: CGFloat = 0
        var showYAxisLabel: Bool = true
        var showYAxisReference: Bool = true
        
        //分区中各个y轴虚线和y轴的label
        //控制y轴的label在左还是右显示
        switch self.showYAxisLabel {
        case .left:
            startX = self.bounds.origin.x - 3 * (self.isInnerYAxis ? -1 : 1)
            extrude = self.bounds.origin.x + self.padding.left - 2
        case .right:
            startX = self.bounds.maxX - self.yAxisLabelWidth + 3 * (self.isInnerYAxis ? -1 : 1)
            extrude = self.bounds.origin.x + self.padding.left + self.bounds.size.width - self.padding.right
            
        case .none:
            showYAxisLabel = false
        }
        
        
        var yaxis = self.yAxis
        var step: CGFloat = 0       //递增值
        //计算y轴间断增值
        if let increaseValue = self.delegate?.incrementValueForYAxisInDepthChart?(in: self) {
           
            step = CGFloat(increaseValue)
            
        } else {
            
            //保持Y轴标签个数偶数显示
            if (yaxis.tickInterval % 2 == 1) {
                yaxis.tickInterval += 1
            }
            
            //计算y轴的标签及虚线分几段
            step = (yaxis.max - yaxis.min) / CGFloat(yaxis.tickInterval)
            
        }
        
        
        
        //从base值绘制Y轴标签到最大值，记录需要绘制的y轴数值
        var yVal = yaxis.baseValue
        while yVal <= yaxis.max && step > 0 {
            
            valueToDraw.insert(yVal)
            
            //递增下一个
            yVal = yVal + step
            
        }
        
        //执行绘制
        for yVal in valueToDraw {
            
            
            //画虚线和Y标签值
            let iy = self.getLocalY(yVal)
            
            if self.isInnerYAxis {
                //y轴标签向内显示，为了不挡住辅助线，所以把y轴的数值位置向上移一些
                startY = iy - 14
            } else {
                startY = iy - 7
            }
            
            let referencePath = UIBezierPath()
            let referenceLayer = CHShapeLayer()
            referenceLayer.lineWidth = self.lineWidth
            
            //处理辅助线样式
            switch self.yAxis.referenceStyle {
            case let .dash(color: dashColor, pattern: pattern):
                referenceLayer.strokeColor = dashColor.cgColor
                referenceLayer.lineDashPattern = pattern
                showYAxisReference = true
            case let .solid(color: solidColor):
                referenceLayer.strokeColor = solidColor.cgColor
                showYAxisReference = true
            default:
                showYAxisReference = false
                startY = iy - 7
            }
            
            if showYAxisReference {
                
                //突出的线段，y轴向外显示才划突出线段
                if !self.isInnerYAxis {
                    referencePath.move(to: CGPoint(x: extrude, y: iy))
                    referencePath.addLine(to: CGPoint(x: extrude + 2, y: iy))
                }
                
                referencePath.move(to: CGPoint(x: self.bounds.origin.x + self.padding.left, y: iy))
                referencePath.addLine(to: CGPoint(x: self.bounds.origin.x + self.bounds.size.width - self.padding.right, y: iy))
                
                referenceLayer.path = referencePath.cgPath
                self.drawLayer.addSublayer(referenceLayer)
            }
            
            if showYAxisLabel {
                
                //获取调用者回调的label字符串值
                let strValue = self.delegate?.depthChart(chart: self, labelOnYAxisForValue: yVal) ?? ""
                
                let yLabelRect = CGRect(x: startX,
                                        y: startY,
                                        width: yAxisLabelWidth,
                                        height: 12
                )
                
                yAxisToDraw.append((yLabelRect, strValue))
                
            }
            
        }
        
        return yAxisToDraw
    }
    
    
    /// 绘制y轴坐标上的标签
    ///
    /// - Parameter yAxisToDraw:
    fileprivate func drawYAxisLabel(_ yAxisToDraw: [(CGRect, String)]) {
        
        var alignmentMode = kCAAlignmentLeft
        //分区中各个y轴虚线和y轴的label
        //控制y轴的label在左还是右显示
        switch self.showYAxisLabel {
        case .left:
            alignmentMode = self.isInnerYAxis ? kCAAlignmentLeft : kCAAlignmentRight
        case .right:
            alignmentMode = self.isInnerYAxis ? kCAAlignmentRight : kCAAlignmentLeft
        case .none:
            alignmentMode = kCAAlignmentLeft
        }
        
        for (yLabelRect, strValue) in yAxisToDraw {
            
            let yAxisLabel = CHTextLayer()
            yAxisLabel.frame = yLabelRect
            yAxisLabel.string = strValue
            yAxisLabel.fontSize = self.labelFont.pointSize
            yAxisLabel.foregroundColor =  self.textColor.cgColor
            yAxisLabel.backgroundColor = UIColor.clear.cgColor
            yAxisLabel.alignmentMode = alignmentMode
            yAxisLabel.contentsScale = UIScreen.main.scale
            
            self.drawLayer.addSublayer(yAxisLabel)
            
        }
    }

    
    /**
     绘制X轴上的标签
     
     - parameter padding: 内边距
     - parameter width:   总宽度
 
    fileprivate func drawXAxis(_ section: CHSection) -> [(CGRect, String)] {
        
        var xAxisToDraw = [(CGRect, String)]()
        
        let xAxis = CHShapeLayer()
        
        var startX: CGFloat = section.frame.origin.x + section.padding.left
        let endX: CGFloat = section.frame.origin.x + section.frame.size.width - section.padding.right
        let secWidth: CGFloat = section.frame.size.width
        let secPaddingLeft: CGFloat = section.padding.left
        let secPaddingRight: CGFloat = section.padding.right
        
        //x轴分平均分4个间断，显示5个x轴坐标，按照图表的值个数，计算每个间断的个数
        let dataRange = self.rangeTo - self.rangeFrom
        let xTickInterval: Int = dataRange / self.xAxisPerInterval
        
        //绘制x轴标签
        //每个点的间隔宽度
        let perPlotWidth: CGFloat = (secWidth - secPaddingLeft - secPaddingRight) / CGFloat(self.rangeTo - self.rangeFrom)
        let startY = section.frame.maxY
        var k: Int = 0
        var showXAxisReference = false
        //相当 for var i = self.rangeFrom; i < self.rangeTo; i = i + xTickInterval
        for i in stride(from: self.rangeFrom, to: self.rangeTo, by: xTickInterval) {
            
            let xLabel = self.delegate?.kLineChart?(chart: self, labelOnXAxisForIndex: i) ?? ""
            var textSize = xLabel.ch_sizeWithConstrained(self.labelFont)
            textSize.width = textSize.width + 4
            var xPox = startX - textSize.width / 2 + perPlotWidth / 2
            //计算最左最右的x轴标签不越过边界
            if (xPox < 0) {
                xPox = startX
            } else if (xPox + textSize.width > endX) {
                xPox = xPox - (xPox + textSize.width - endX)
            }
            //        NSLog(@"xPox = %f", xPox)
            //        NSLog(@"textSize.width = %f", textSize.width)
            let barLabelRect = CGRect(x: xPox, y: startY, width: textSize.width, height: textSize.height)
            
            //记录待绘制的文本
            xAxisToDraw.append((barLabelRect, xLabel))
            
            //绘制辅助线
            let referencePath = UIBezierPath()
            let referenceLayer = CHShapeLayer()
            referenceLayer.lineWidth = self.lineWidth
            
            //处理辅助线样式
            switch section.xAxis.referenceStyle {
            case let .dash(color: dashColor, pattern: pattern):
                referenceLayer.strokeColor = dashColor.cgColor
                referenceLayer.lineDashPattern = pattern
                showXAxisReference = true
            case let .solid(color: solidColor):
                referenceLayer.strokeColor = solidColor.cgColor
                showXAxisReference = true
            default:
                showXAxisReference = false
            }
            
            //需要画x轴上的辅助线
            if showXAxisReference {
                referencePath.move(to: CGPoint(x: xPox + textSize.width / 2, y: section.frame.minY))
                referencePath.addLine(to: CGPoint(x: xPox + textSize.width / 2, y: section.frame.maxY))
                referenceLayer.path = referencePath.cgPath
                xAxis.addSublayer(referenceLayer)
            }
            
            
            k = k + xTickInterval
            startX = perPlotWidth * CGFloat(k)
        }
        
        self.drawLayer.addSublayer(xAxis)
        
        return xAxisToDraw
    }
    */
    
    /// 绘制X坐标标签
    ///
    /// - Parameters:
    ///   - section: 哪个分区绘制
    ///   - xAxisToDraw: 待绘制的内容
    fileprivate func drawXAxisLabel(xAxisToDraw: [(CGRect, String)]) {
        
        guard self.showXAxisLabel else {
            return
        }
        
        guard xAxisToDraw.count > 0 else {
            return
        }
        
        let xAxis = CHShapeLayer()
        
        let startY = self.bounds.maxY //需要显示x坐标标签名字的分区，再最下方显示
        //绘制x坐标标签，x的位置通过画辅助线时计算得出
        for (var barLabelRect, xLabel) in xAxisToDraw {
            
            barLabelRect.origin.y = startY
            
            //绘制文本
            let xLabelText = CHTextLayer()
            xLabelText.frame = barLabelRect
            xLabelText.string = xLabel
            xLabelText.alignmentMode = kCAAlignmentCenter
            xLabelText.fontSize = self.labelFont.pointSize
            xLabelText.foregroundColor =  self.textColor.cgColor
            xLabelText.backgroundColor = UIColor.clear.cgColor
            xLabelText.contentsScale = UIScreen.main.scale
            
            xAxis.addSublayer(xLabelText)
            
        }
        
        self.drawLayer.addSublayer(xAxis)
        //        context?.strokePath()
    }

    
    /**
     绘制图表上的点线
     
     - parameter section:
     */
    func drawChart() {
        
        var startIndex = 0
        
        
        //绘制买方深度图层
        if let bidChartLayer = self.drawDepthChart(items: self.bidItems, startIndex: 0, strokeColor: self.bidColor.stroke, fillColor: self.bidColor.fill, lineWidth: self.bidColor.lineWidth) {
            self.drawLayer.addSublayer(bidChartLayer)
            startIndex = self.bidItems.count
        }
        
        //绘制卖方深度图层
        if let askChartLayer = self.drawDepthChart(items: self.askItems, startIndex: startIndex, strokeColor: self.askColor.stroke, fillColor: self.askColor.fill, lineWidth: self.askColor.lineWidth) {
            self.drawLayer.addSublayer(askChartLayer)
        }
    }
    
    
    
    /// 绘制买单深度图层
    ///
    /// - Parameters:
    ///   - items: 数据集
    ///   - startIndex: 数据起始位置
    ///   - strokeColor: 线条颜色
    ///   - fillColor: 填充颜色
    func drawDepthChart(items: [CHKDepthChartItem],
                        startIndex: Int,
                        strokeColor: UIColor,
                        fillColor: UIColor,
                        lineWidth: CGFloat) -> CAShapeLayer? {
        
        guard self.plotCount > 0 else {
            return nil
        }
        
        let depthChart = CAShapeLayer()
        let lineLayer = CAShapeLayer()
        let fillLayer = CAShapeLayer()
        
        // 【一】绘制线段
        
        //使用bezierPath画线段
        let linePath = UIBezierPath()
        var isStartDraw = false
        
        //循环起始到终结，绘制线段
        var index: Int = 0
        var startX: CGFloat = 0
        var endX: CGFloat = 0
        for (i, item) in items.enumerated() {
            
            //开始的点
            index = startIndex + i
            
            //开始X
            var ix = self.bounds.origin.x + self.padding.left + CGFloat(index) * plotWidth
            
            //把具体的数值转为坐标系的y值
            let iys = self.getLocalY(item.depthAmount)
            
            //第一个点移动路径起始
            switch i {
            case 0: //第一个点的特殊处理，把线条闭合
                ix += 0
                startX = ix
            case items.count - 1:   //最后一个点的特殊处理，把线条闭合
                ix += plotWidth
            default:                //其它点取正中
                ix += plotWidth / 2
            }
            
            let point = CGPoint(x: ix, y: iys)
            
            if !isStartDraw {
                linePath.move(to: point)
                isStartDraw = true
            } else {
                linePath.addLine(to: point)
            }
            
            endX = point.x
        }
        
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = strokeColor.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = lineWidth
        lineLayer.lineCap = kCALineCapRound
        lineLayer.lineJoin = kCALineJoinBevel
        depthChart.addSublayer(lineLayer)
        
        // 【二】绘制填充区域
        
        linePath.addLine(to: CGPoint(x: endX, y: self.bounds.maxY - self.padding.bottom))
        linePath.addLine(to: CGPoint(x: startX, y: self.bounds.maxY - self.padding.bottom))
        fillLayer.path = linePath.cgPath
        fillLayer.fillColor = fillColor.cgColor
        fillLayer.strokeColor = UIColor.clear.cgColor
        fillLayer.zPosition -= 1 // 将图层置于下一级，让底部的标记线显示出来
        depthChart.addSublayer(fillLayer)
        
        return depthChart
        
    }
    
}

// MARK: - 公开方法
extension CHDepthChartView {
    
    /**
     刷新视图
     */
    public func reloadData() {
        self.resetData()
        self.drawLayerView()
    }
    
    
    /// 刷新风格
    ///
    /// - Parameter style: 新风格
    public func resetStyle(style: CHKLineChartStyle) {
        self.style = style
        self.reloadData()
    }
    
    /// 生成截图
    var image: UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return capturedImage!
    }
}


// MARK: - 手势操作
extension CHDepthChartView: UIGestureRecognizerDelegate {
    
    
    /// 控制手势开关
    ///
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        switch gestureRecognizer {
        case is UITapGestureRecognizer:
            return self.enableTap
        default:
            return false
        }
    }
    
    /**
     *  点击事件处理
     *
     *  @param sender
     */
    @objc func doTapAction(_ sender: UITapGestureRecognizer) {
        
        guard self.enableTap else {
            return
        }
        
        let point = sender.location(in: self)
        
        //显示点击选中的内容
        self.setSelectedIndexByPoint(point)
    }
    
    
    
}
