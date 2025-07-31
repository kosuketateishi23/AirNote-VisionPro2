import UIKit

/// カードのテクスチャを動的に生成するためのヘルパー
enum TextureGenerator {

    static func imageWithText(_ text: String, backgroundColor: UIColor) -> UIImage {
        let size = CGSize(width: 512, height: 340)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // ▼▼▼ 変更点 ▼▼▼
            // バツマークの描画処理を追加
            let buttonDiameter: CGFloat = 50
            let buttonMargin: CGFloat = 15
            let buttonRect = CGRect(x: buttonMargin, y: buttonMargin, width: buttonDiameter, height: buttonDiameter)
            context.cgContext.setFillColor(UIColor.systemRed.cgColor)
            context.cgContext.fillEllipse(in: buttonRect)
            let path = UIBezierPath()
            let xMargin = buttonRect.minX + buttonDiameter * 0.25
            let yMargin = buttonRect.minY + buttonDiameter * 0.25
            let xMax = buttonRect.maxX - buttonDiameter * 0.25
            let yMax = buttonRect.maxY - buttonDiameter * 0.25
            path.move(to: CGPoint(x: xMargin, y: yMargin))
            path.addLine(to: CGPoint(x: xMax, y: yMax))
            path.move(to: CGPoint(x: xMax, y: yMargin))
            path.addLine(to: CGPoint(x: xMargin, y: yMax))
            UIColor.white.setStroke()
            path.lineWidth = 5
            path.lineCapStyle = .round
            path.stroke()
            // ▲▲▲ ここまで変更 ▲▲▲

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byWordWrapping
            
            let fontSize: CGFloat = text.count <= 5 ? 128 : max(64, 128 - CGFloat(text.count - 5) * 6)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraph
            ]
            
            let textRect = CGRect(x: 20, y: (size.height - 180) / 2, width: size.width - 40, height: 180)
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }
    }

    static func imageWithBackSide(
        english: String, japanese: String, partOfSpeech: String, memo: String, backgroundColor: UIColor
    ) -> UIImage {
        let size = CGSize(width: 512, height: 340)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let textColor = UIColor.black
            let padding: CGFloat = 20
            let engAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 32, weight: .semibold), .foregroundColor: textColor]
            (english as NSString).draw(at: CGPoint(x: padding, y: padding), withAttributes: engAttrs)
            let posAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 28), .foregroundColor: UIColor.darkGray]
            let posString = (partOfSpeech as NSString)
            let posSize = posString.size(withAttributes: posAttrs)
            posString.draw(at: CGPoint(x: size.width - padding - posSize.width, y: padding + 4), withAttributes: posAttrs)
            let jpParagraph = NSMutableParagraphStyle()
            jpParagraph.alignment = .center
            jpParagraph.lineBreakMode = .byWordWrapping
            let jpFontSize: CGFloat = japanese.count <= 5 ? 96 : max(42, 96 - CGFloat(japanese.count - 5) * 5)
            let jpAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: jpFontSize, weight: .bold), .foregroundColor: textColor, .paragraphStyle: jpParagraph]
            let jpRect = CGRect(x: 10, y: size.height / 2 - 80, width: size.width - 20, height: 160)
            (japanese as NSString).draw(in: jpRect, withAttributes: jpAttrs)
            if !memo.isEmpty {
                let memoAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22), .foregroundColor: textColor]
                let memoRect = CGRect(x: 20, y: size.height - 80, width: size.width - 40, height: 60)
                (memo as NSString).draw(in: memoRect, withAttributes: memoAttrs)
            }
        }
    }
}
// ▼▼▼ 変更点 ▼▼▼
// ここにあった extension Card { ... } を削除
