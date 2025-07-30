import UIKit

/// カードのテクスチャを動的に生成するためのヘルパー
enum TextureGenerator {

    static func imageWithText(_ text: String, backgroundColor: UIColor) -> UIImage {
        let size = CGSize(width: 512, height: 340)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        let fontSize: CGFloat = text.count <= 5 ? 128 : max(64, 128 - CGFloat(text.count - 5) * 6)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph
        ]
        let textRect = CGRect(x: 20, y: (size.height - 180) / 2, width: size.width - 40, height: 180)
        (text as NSString).draw(in: textRect, withAttributes: attributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    static func imageWithBackSide(
        english: String, japanese: String, partOfSpeech: String, memo: String, backgroundColor: UIColor
    ) -> UIImage {
        let size = CGSize(width: 512, height: 340)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let engFontSize: CGFloat = english.count <= 5 ? 64 : max(32, 64 - CGFloat(english.count - 5) * 4)
        let engFont = UIFont.systemFont(ofSize: engFontSize)
        let engAttributes: [NSAttributedString.Key: Any] = [ .font: engFont, .foregroundColor: UIColor.black ]
        (english as NSString).draw(in: CGRect(x: 20, y: 20, width: 320, height: 60), withAttributes: engAttributes)

        let posFont = UIFont.systemFont(ofSize: 56)
        let posAttributes: [NSAttributedString.Key: Any] = [ .font: posFont, .foregroundColor: UIColor.gray ]
        (partOfSpeech as NSString).draw(in: CGRect(x: size.width - 140, y: 22, width: 120, height: 60), withAttributes: posAttributes)

        let baseSize: CGFloat = japanese.count <= 5 ? 96 : max(42, 96 - CGFloat(japanese.count - 5) * 5)
        let jpFont = UIFont.systemFont(ofSize: baseSize)
        let jpParagraph = NSMutableParagraphStyle()
        jpParagraph.alignment = .center
        jpParagraph.lineBreakMode = .byWordWrapping
        let jpAttributes: [NSAttributedString.Key: Any] = [ .font: jpFont, .foregroundColor: UIColor.black, .paragraphStyle: jpParagraph ]
        (japanese as NSString).draw(in: CGRect(x: 10, y: size.height / 2 - 70, width: size.width - 20, height: 200), withAttributes: jpAttributes)
        
        if !memo.isEmpty {
            let memoFrame = CGRect(x: 80, y: 230, width: 352, height: 80)
            let memoPath = UIBezierPath(roundedRect: memoFrame, cornerRadius: 12)
            UIColor(white: 0.85, alpha: 1.0).setStroke()
            context.setLineWidth(2)
            memoPath.stroke()

            let memoFont = UIFont.systemFont(ofSize: 22)
            let memoAttributes: [NSAttributedString.Key: Any] = [ .font: memoFont, .foregroundColor: UIColor.black, .paragraphStyle: jpParagraph ]
            let memoTextRect = memoFrame.insetBy(dx: 10, dy: 10)
            (memo as NSString).draw(in: memoTextRect, withAttributes: memoAttributes)
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension Card {
    /// カードの色名からUIColorを返す computed property
    var uiColor: UIColor {
        switch self.colorName {
            case "pink": return UIColor(red: 1.0, green: 0.92, blue: 0.93, alpha: 1.0)
            case "blue": return UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
            case "green": return UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
            case "gray": return UIColor(white: 0.95, alpha: 1.0)
            default: return UIColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1.0) // beige
        }
    }
}
