import Foundation
import RealityKit
import UIKit

/// Blender等で作成した3Dモデルをベースにしたカードエンティティ
class ModeledNoteCardEntity: Entity {

    let card: Card
    private let baseModel: Entity
    private var flipAnimation: AnimationResource?
    private var reverseFlipAnimation: AnimationResource?
    private var stickAnimation: AnimationResource?
    private var isFlipped = false
    private var deleteButton: Entity? // ModelEntityからEntityに変更

    init(card: Card, sceneTemplate: Entity) {
        self.card = card

        guard let modelTemplate = sceneTemplate.findEntity(named: "_default") else {
            fatalError("シーン内に '_default' という名前のエンティティが見つかりません。")
        }
        self.baseModel = modelTemplate.clone(recursive: true)

        if let animationSourceEntity = sceneTemplate.findEntity(named: "flip") {
            let animationName = "default subtree animation"
            if let animResource = animationSourceEntity.availableAnimations.first(where: { $0.name == animationName }) {
                self.flipAnimation = animResource
            }
        }
        
        if let reverseAnimationSourceEntity = sceneTemplate.findEntity(named: "reverseflip") {
            let reverseAnimationName = "default subtree animation"
            if let animResource = reverseAnimationSourceEntity.availableAnimations.first(where: { $0.name == reverseAnimationName }) {
                self.reverseFlipAnimation = animResource
            }
        }
        
        if let stickAnimationSourceEntity = sceneTemplate.findEntity(named: "stick") {
            let stickAnimationName = "default subtree animation"
            if let animResource = stickAnimationSourceEntity.availableAnimations.first(where: { $0.name == stickAnimationName }) {
                self.stickAnimation = animResource
            }
        }

        super.init()
        self.addChild(baseModel)
        
        if card.id == CardStore.shared.justAddedCardID {
            playStickAnimation()
            CardStore.shared.justAddedCardID = nil
        }
        
        applyTextures()
        addInteractionControls()
        self.generateCollisionShapes(recursive: true)
        self.components.set(InputTargetComponent())
        self.components.set(HoverEffectComponent())
        
        let scaleFactor: Float
        switch card.size {
        case "小": scaleFactor = 0.5
        case "中": scaleFactor = 0.7
        default: scaleFactor = 1.0
        }
        self.scale = [scaleFactor, scaleFactor, scaleFactor]
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    func flip() {
        if isFlipped {
            guard let animationToPlay = self.reverseFlipAnimation else { return }
            baseModel.playAnimation(animationToPlay, transitionDuration: 0.2)
        } else {
            guard let animationToPlay = self.flipAnimation else { return }
            baseModel.playAnimation(animationToPlay, transitionDuration: 0.2)
        }
        isFlipped.toggle()
        deleteButton?.components[InputTargetComponent.self]?.isEnabled = !isFlipped
    }
    
    func flip(toFront: Bool) {
        if toFront && isFlipped {
            guard let animationToPlay = self.reverseFlipAnimation else { return }
            baseModel.playAnimation(animationToPlay, transitionDuration: 0.2)
            isFlipped = false
        } else if !toFront && !isFlipped {
            guard let animationToPlay = self.flipAnimation else { return }
            baseModel.playAnimation(animationToPlay, transitionDuration: 0.2)
            isFlipped = true
        }
        deleteButton?.components[InputTargetComponent.self]?.isEnabled = !isFlipped
    }
    
    func playStickAnimation() {
        guard let animationToPlay = self.stickAnimation else { return }
        baseModel.playAnimation(animationToPlay, transitionDuration: 0.2)
    }

    private func applyTextures() {
        let frontImage = TextureGenerator.imageWithText(card.english, backgroundColor: card.uiColor)
        guard let frontCGImage = frontImage.cgImage,
              let frontTexture = try? TextureResource(image: frontCGImage, options: .init(semantic: .color)) else { return }
        
        let backImage = TextureGenerator.imageWithBackSide(
            english: card.english, japanese: card.japanese, partOfSpeech: card.partOfSpeech, memo: card.memo, backgroundColor: card.uiColor
        )
        guard let backCGImage = backImage.cgImage,
              let backTexture = try? TextureResource(image: backCGImage, options: .init(semantic: .color)) else { return }

        let allModelEntities = baseModel.findAllDescendants(ofType: ModelEntity.self)
        if allModelEntities.isEmpty { return }
        for modelEntity in allModelEntities {
            guard let materialName = modelEntity.model?.materials.first?.name else { continue }
            if materialName == "BackMaterial" {
                var newMaterial = SimpleMaterial()
                newMaterial.color = .init(texture: .init(frontTexture))
                modelEntity.model?.materials = [newMaterial]
            } else if materialName == "FrontMaterial" {
                var newMaterial = SimpleMaterial()
                newMaterial.color = .init(texture: .init(backTexture))
                modelEntity.model?.materials = [newMaterial]
            }
        }
    }
    
    private func addInteractionControls() {
        let cardWidth: Float = 0.707
        let cardHeight: Float = 0.5
        let button3DSize: Float = (50.0 / 512.0) * cardWidth
        
        // ▼▼▼ 変更点 ▼▼▼
        // 1. 見た目を持たない、空のエンティティを作成する
        let button = Entity()
        button.name = "deleteButton"
        
        // 2. 当たり判定の「形状」を直接コンポーネントとして設定する
        let buttonShape = ShapeResource.generateBox(size: [button3DSize, button3DSize, 0.002])
        button.components.set(CollisionComponent(shapes: [buttonShape]))
        
        // 3. タップに反応するようにInputTargetComponentを設定する
        button.components.set(InputTargetComponent())
        
        button.position = [
            -cardWidth / 2 + button3DSize / 2+0.022,
             cardHeight / 2 - button3DSize / 2-0.024,
             0.011
        ]
        
        self.baseModel.addChild(button)
        
        // ドラッグハンドル削除
        
        self.deleteButton = button
    }
}

// MARK: - Entityを再帰的に検索するためのヘルパー拡張機能
extension Entity {
    func findAllDescendants<T: Entity>(ofType type: T.Type) -> [T] {
        var result: [T] = []
        for child in children {
            if let typedChild = child as? T {
                result.append(typedChild)
            }
            result.append(contentsOf: child.findAllDescendants(ofType: type))
        }
        return result
    }
}
