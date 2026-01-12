//  IbInspectables.swift
//  Created by Anmol.

import UIKit

extension UIView{
@IBInspectable var cornerRadius: Double {
             get {
               return Double(self.layer.cornerRadius)
             }set {
               self.layer.cornerRadius = CGFloat(newValue)
             }
        }
        @IBInspectable var borderWidth: Double {
              get {
                return Double(self.layer.borderWidth)
              }
              set {
               self.layer.borderWidth = CGFloat(newValue)
              }
        }
        @IBInspectable var borderColor: UIColor? {
             get {
                return UIColor(cgColor: self.layer.borderColor!)
             }
             set {
                self.layer.borderColor = newValue?.cgColor
             }
        }
        @IBInspectable
        var shadowColor: UIColor? {
            get {
               return UIColor(cgColor: self.layer.shadowColor!)
            }
            set {
               self.layer.shadowColor = newValue?.cgColor
            }
        }
        @IBInspectable
        var shadowOpacity: Float {
            get {
               return self.layer.shadowOpacity
            }
            set {
               self.layer.shadowOpacity = newValue
           }
        }
     
    }
@IBDesignable class TextViewWithInsets: UITextView {
 
    @IBInspectable
    var topInset: CGFloat = 0 {
        didSet {
            self.contentInset = UIEdgeInsets(top: topInset, left: self.contentInset.left, bottom: self.contentInset.bottom, right: self.contentInset.right)
        }
    }
 
    @IBInspectable
    var bottmInset: CGFloat = 0 {
        didSet {
            self.contentInset = UIEdgeInsets(top: self.contentInset.top, left: self.contentInset.left, bottom: bottmInset, right: self.contentInset.right)
        }
    }
 
    @IBInspectable
    var leftInset: CGFloat = 0 {
        didSet {
            self.contentInset = UIEdgeInsets(top: self.contentInset.top, left: leftInset, bottom: self.contentInset.bottom, right: self.contentInset.right)
        }
    }
 
    @IBInspectable
    var rightInset: CGFloat = 0 {
        didSet {
            self.contentInset = UIEdgeInsets(top: self.contentInset.top, left: self.contentInset.left, bottom: self.contentInset.bottom, right: rightInset)
        }
    }
}
 
