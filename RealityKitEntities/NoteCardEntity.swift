import Foundation
import RealityKit
import UIKit

class NoteCardEntity: Entity, HasModel, HasCollision {
    var isFlipped = false
    let card: Card
    let baseEntity: Entity
    let frontPlane: ModelEntity
    let frontMaterial: UnlitMaterial
    let backMaterial: UnlitMaterial

    init(card: Card) {
        self.card = card

        let cardWidth: Float = 0.3
        let cardHeight: Float = 0.2
        let cardSize = SIMD3<Float>(cardWidth, cardHeight, 0.005)

        let backgroundColor = UIColor(red: 255/255, green: 251/255, blue: 236/255, alpha: 1.0)

        let frontImage = NoteCardEntity.imageWithText(card.english, backgroundColor: backgroundColor)
        let frontTexture = try! TextureResource(image: frontImage.cgImage!, options: .init(semantic: .color))
        var frontMat = UnlitMaterial()
        frontMat.color.texture = MaterialParameters.Texture(frontTexture)
        self.frontMaterial = frontMat

        let backImage = NoteCardEntity.imageWithBackSide(
            english: card.english,
            japanese: card.japanese,
            partOfSpeech: card.partOfSpeech,
            memo: card.memo,
            backgroundColor: backgroundColor
        )
        let backTexture = try! TextureResource(image: backImage.cgImage!, options: .init(semantic: .color))
        var backMat = UnlitMaterial()
        backMat.color.texture = MaterialParameters.Texture(backTexture)
        self.backMaterial = backMat

        self.baseEntity = Entity()

        let planeMesh = MeshResource.generatePlane(width: cardWidth, height: cardHeight)
        self.frontPlane = ModelEntity(mesh: planeMesh, materials: [self.frontMaterial])
        frontPlane.position.z = 0.0025
        frontPlane.generateCollisionShapes(recursive: true)
        frontPlane.components.set(InputTargetComponent())

        let backPlane = ModelEntity(mesh: planeMesh, materials: [self.backMaterial])
        backPlane.position.z = -0.0025
        backPlane.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])

        baseEntity.addChild(frontPlane)
        baseEntity.addChild(backPlane)

        let buttonSize: Float = 0.03
        let redColor = UIColor(red: 236/255, green: 106/255, blue: 94/255, alpha: 1.0)
        let redBoxMesh = MeshResource.generatePlane(width: buttonSize, height: buttonSize)
        var redMaterial = UnlitMaterial()
        redMaterial.color = .init(tint: redColor)
        let deleteButton = ModelEntity(mesh: redBoxMesh, materials: [redMaterial])
        deleteButton.name = "deleteButton"
        deleteButton.generateCollisionShapes(recursive: true)
        deleteButton.components.set(InputTargetComponent())

        let xMesh = MeshResource.generateText("×",
            extrusionDepth: 0.0001,
            font: .boldSystemFont(ofSize: 0.03),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byCharWrapping)
        var xMaterial = UnlitMaterial()
        xMaterial.color = .init(tint: .white)
        let xEntity = ModelEntity(mesh: xMesh, materials: [xMaterial])
        xEntity.setPosition([-0.011, -0.013, 0.001], relativeTo: nil)
        deleteButton.addChild(xEntity)

        deleteButton.position = SIMD3<Float>(
            -cardWidth / 2 + buttonSize / 2 + 0.01,
            cardHeight / 2 - buttonSize / 2 - 0.01,
            0.003
        )
        frontPlane.addChild(deleteButton)

        // ✅ ドラッグハンドル（カード下の灰色バー）を追加
        let handleWidth: Float = 0.15
        let handleHeight: Float = 0.015
        let handleMesh = MeshResource.generatePlane(width: handleWidth, height: handleHeight)
        var handleMaterial = UnlitMaterial()
        handleMaterial.color = .init(tint: .gray)
        let dragHandle = ModelEntity(mesh: handleMesh, materials: [handleMaterial])
        dragHandle.name = "dragHandle"
        dragHandle.position = SIMD3<Float>(0, -cardHeight / 2 - 0.01, 0.002)
        dragHandle.generateCollisionShapes(recursive: true)
        dragHandle.components.set(InputTargetComponent())
        baseEntity.addChild(dragHandle)

        super.init()
        self.addChild(baseEntity)
        self.generateCollisionShapes(recursive: true)
        self.collision = CollisionComponent(shapes: [.generateBox(size: cardSize)])
        self.components.set(InputTargetComponent())
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    func flip() {
        isFlipped.toggle()
        let angle: Float = isFlipped ? .pi : 0
        let newRotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        baseEntity.move(
            to: Transform(
                scale: baseEntity.transform.scale,
                rotation: newRotation,
                translation: baseEntity.transform.translation
            ),
            relativeTo: baseEntity.parent,
            duration: 0.6,
            timingFunction: .easeInOut
        )
    }

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
        let textRect = CGRect(x: 20, y: 80, width: size.width - 40, height: 180)
        (text as NSString).draw(in: textRect, withAttributes: attributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    static func imageWithBackSide(
        english: String,
        japanese: String,
        partOfSpeech: String,
        memo: String,
        backgroundColor: UIColor
    ) -> UIImage {
        let size = CGSize(width: 512, height: 340)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let engFontSize: CGFloat = english.count <= 5 ? 64 : max(32, 64 - CGFloat(english.count - 5) * 4)
        let engFont = UIFont.systemFont(ofSize: engFontSize)
        let engAttributes: [NSAttributedString.Key: Any] = [
            .font: engFont,
            .foregroundColor: UIColor.black
        ]
        let engRect = CGRect(x: 20, y: 20, width: 320, height: 60)
        (english as NSString).draw(in: engRect, withAttributes: engAttributes)

        let posFont = UIFont.systemFont(ofSize: 56)
        let posAttributes: [NSAttributedString.Key: Any] = [
            .font: posFont,
            .foregroundColor: UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1.0)
        ]
        let posRect = CGRect(x: size.width - 140, y: 22, width: 120, height: 60)
        (partOfSpeech as NSString).draw(in: posRect, withAttributes: posAttributes)

        let baseSize: CGFloat = japanese.count <= 5 ? 96 : max(42, 96 - CGFloat(japanese.count - 5) * 5)
        let jpFont = UIFont.systemFont(ofSize: baseSize)
        let jpParagraph = NSMutableParagraphStyle()
        jpParagraph.alignment = .center
        jpParagraph.lineBreakMode = .byWordWrapping

        let jpAttributes: [NSAttributedString.Key: Any] = [
            .font: jpFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: jpParagraph
        ]
        let jpRect = CGRect(x: 10, y: size.height / 2 - 70, width: size.width - 20, height: 200)
        (japanese as NSString).draw(in: jpRect, withAttributes: jpAttributes)

        let memoFrame = CGRect(x: 80, y: 230, width: 352, height: 80)
        let memoPath = UIBezierPath(roundedRect: memoFrame, cornerRadius: 12)
        UIColor(white: 0.85, alpha: 1.0).setStroke()
        context.setLineWidth(2)
        memoPath.stroke()

        let memoFont = UIFont.systemFont(ofSize: 22)
        let memoAttributes: [NSAttributedString.Key: Any] = [
            .font: memoFont,
            .foregroundColor: UIColor.black,
            .paragraphStyle: jpParagraph
        ]
        let memoTextRect = memoFrame.insetBy(dx: 10, dy: 10)
        (memo as NSString).draw(in: memoTextRect, withAttributes: memoAttributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
