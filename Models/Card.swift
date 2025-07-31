import Foundation
import simd
import UIKit // UIColorを使うためにUIKitをインポート

struct Card: Identifiable, Codable, Equatable {
    var id = UUID()
    var english: String
    var japanese: String
    var partOfSpeech: String
    var memo: String
    var colorName: String
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var size: String

    enum CodingKeys: CodingKey {
        case id, english, japanese, partOfSpeech, memo, colorName, position, rotation, size
    }

    init(english: String, japanese: String, partOfSpeech: String, memo: String, colorName: String, position: SIMD3<Float>, rotation: simd_quatf, size: String) {
        self.english = english
        self.japanese = japanese
        self.partOfSpeech = partOfSpeech
        self.memo = memo
        self.colorName = colorName
        self.position = position
        self.rotation = rotation
        self.size = size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english)
        japanese = try container.decode(String.self, forKey: .japanese)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        memo = try container.decode(String.self, forKey: .memo)
        colorName = try container.decode(String.self, forKey: .colorName)
        position = try container.decode(SIMD3<Float>.self, forKey: .position)
        let rotationArray = try container.decode([Float].self, forKey: .rotation)
        rotation = simd_quatf(ix: rotationArray[0], iy: rotationArray[1], iz: rotationArray[2], r: rotationArray[3])
        size = try container.decodeIfPresent(String.self, forKey: .size) ?? "大"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(english, forKey: .english)
        try container.encode(japanese, forKey: .japanese)
        try container.encode(partOfSpeech, forKey: .partOfSpeech)
        try container.encode(memo, forKey: .memo)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(position, forKey: .position)
        try container.encode([rotation.imag.x, rotation.imag.y, rotation.imag.z, rotation.real], forKey: .rotation)
        try container.encode(size, forKey: .size)
    }
}

// ▼▼▼ 変更点 ▼▼▼
// Cardの拡張機能を、TextureGenerator.swiftからこちらに移動
extension Card {
    /// カードの色名（String）から、実際のUIColorを生成して返す便利なプロパティ
    var uiColor: UIColor {
        switch self.colorName {
        case "pink":
            return UIColor(red: 1.0, green: 0.92, blue: 0.93, alpha: 1.0)
        case "blue":
            return UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        case "green":
            return UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
        case "gray":
            return UIColor(white: 0.95, alpha: 1.0)
        default: // "beige" もしくは未指定の場合
            return UIColor(red: 1.0, green: 0.98, blue: 0.9, alpha: 1.0)
        }
    }
}
