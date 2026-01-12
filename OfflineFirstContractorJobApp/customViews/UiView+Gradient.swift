//  UiView+Gradient.swift
//  OfflineFirstContractorJobApp

import UIKit

// MARK: - UIView Gradient
extension UIView {

    func applyGradient(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) {

        // Remove existing gradient layers
        layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint

        layer.insertSublayer(gradientLayer, at: 0)
    }
}

// MARK: - UIView Shadow
extension UIView {

    func applyShadow(
        color: UIColor = UIColor.black.withAlphaComponent(0.25),
        opacity: Float = 1,
        offset: CGSize = CGSize(width: 0, height: 4),
        radius: CGFloat = 10
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
}

// MARK: - UIButton Gradient + Corner Radius + Shadow
extension UIButton {

    func applyGradient(
        colors: [UIColor],
        cornerRadius: CGFloat = 16,
        shadowColor: UIColor? = nil
    ) {
        // Check if gradient already exists
        if let existingGradient = layer.sublayers?.first(where: { $0.name == "buttonGradient" }) as? CAGradientLayer {
            // Update existing gradient frame and colors
            existingGradient.frame = bounds
            existingGradient.colors = colors.map { $0.cgColor }
            existingGradient.cornerRadius = cornerRadius
            // Update shadow path if shadow exists
            if shadowColor != nil {
                layer.shadowPath = UIBezierPath(
                    roundedRect: bounds,
                    cornerRadius: cornerRadius
                ).cgPath
            }
            return
        }

        // Remove any existing gradient layers (safety check)
        layer.sublayers?
            .filter { $0.name == "buttonGradient" }
            .forEach { $0.removeFromSuperlayer() }

        // Button shape
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false   // Needed for shadow

        // Gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "buttonGradient"
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.masksToBounds = true   // ✅ FIXES CORNER RADIUS

        layer.insertSublayer(gradientLayer, at: 0)

        // Shadow
        if let shadowColor {
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOpacity = 1
            layer.shadowOffset = CGSize(width: 0, height: 8)
            layer.shadowRadius = 16
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: cornerRadius
            ).cgPath
        }
    }
}

// MARK: - UIColor HEX
extension UIColor {

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension UIView {

    func applyRadialGradient(
        centerColor: UIColor,
        edgeColor: UIColor
    ) {
        layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .radial
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            centerColor.cgColor,
            edgeColor.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1.0, y: 1.0)

        layer.insertSublayer(gradientLayer, at: 0)
    }
}

