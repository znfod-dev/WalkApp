//
//  NumericAnimatedLabel.swift
//  WalkApp
//
//  Created by ParkJonghyun on 2021/03/31.
//

import UIKit

public class NumericAnimatedLabel: UILabel {
    
    var animationTimer: Timer?
    var targetValue: Int = 0
    var currentValue: Int = 0
    var stepSize: Int = 0
    
    var format = "%@"
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addConstraint(_ newView: UIView, toView: UIView, attribute: NSLayoutConstraint.Attribute, constant: CGFloat) {
        let constraint =  NSLayoutConstraint(item: newView, attribute: attribute, relatedBy: .equal, toItem: toView, attribute: attribute, multiplier: 1.0, constant: constant)
        toView.addConstraint(constraint)
    }
    
    public func setValue(value: Int) {
        if animationTimer != nil {
            animationTimer?.invalidate()
        }
        
        targetValue = value
        stepSize = (targetValue - currentValue) / 20
        
        animationTimer = Timer.scheduledTimer(timeInterval: (1/40), target: self, selector: #selector(onAnimationTimer), userInfo: nil, repeats: true)
        
    }
    
    @objc func onAnimationTimer() {
        currentValue += stepSize
        updateCurrentValue(value: currentValue)
        if stepSize < 0 {
            if currentValue < targetValue {
                //done decreasing
                currentValue = targetValue
                updateCurrentValue(value: targetValue)
                if (animationTimer) != nil {
                    animationTimer?.invalidate()
                    animationTimer = nil
                }
            }
        } else {
            if currentValue > targetValue {
                //done increasing
                currentValue = targetValue
                updateCurrentValue(value: targetValue)
                if (animationTimer) != nil {
                    animationTimer?.invalidate()
                    animationTimer = nil
                }
            }
        }
    }
    
    func updateCurrentValue(value: Int) {
        self.text = String(format: format, value.addCommas())
    }
}
extension Int {
    func addCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }
}
