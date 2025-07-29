import Foundation
import simd

struct Card: Identifiable, Codable {
    var id = UUID()
    var english: String
    var japanese: String
    var partOfSpeech: String
    var memo: String
    var colorName: String
    var position: SIMD3<Float>
    var rotation: simd_quatf

    enum CodingKeys: CodingKey {
        case id, english, japanese, partOfSpeech, memo, colorName, position, rotation
    }

    init(english: String, japanese: String, partOfSpeech: String, memo: String, colorName: String, position: SIMD3<Float>, rotation: simd_quatf) {
        self.english = english
        self.japanese = japanese
        self.partOfSpeech = partOfSpeech
        self.memo = memo
        self.colorName = colorName
        self.position = position
        self.rotation = rotation
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
    }
}
