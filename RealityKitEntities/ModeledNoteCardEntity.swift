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
        
        playStickAnimation()
        
        applyTextures()
        addInteractionControls()
        self.generateCollisionShapes(recursive: true)
        self.components.set(InputTargetComponent())
        
        let scaleFactor: Float
        switch card.size {
        case "小":
            scaleFactor = 0.5
        case "中":
            scaleFactor = 0.7
        default:
            scaleFactor = 1.0
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
        let cardWidth: Float = 0.707, cardHeight: Float = 0.5, buttonSize: Float = 0.03
        let deleteButton = ModelEntity(mesh: .generatePlane(width: buttonSize, height: buttonSize, cornerRadius: 0.005), materials: [UnlitMaterial(color: .systemRed)])
        deleteButton.name = "deleteButton"
        deleteButton.generateCollisionShapes(recursive: true)
        deleteButton.components.set(InputTargetComponent())
        deleteButton.position = [ -cardWidth / 2 + 0.01, cardHeight / 2 - 0.01, 0.01 ]
        self.addChild(deleteButton)
        let handleMesh = MeshResource.generatePlane(width: 0.15, height: 0.015, cornerRadius: 0.007)
        let handleMaterial = UnlitMaterial(color: .gray)
        let dragHandle = ModelEntity(mesh: handleMesh, materials: [handleMaterial])
        dragHandle.name = "dragHandle"
        dragHandle.position = [0, -cardHeight / 2 - 0.01, 0.01]
        dragHandle.generateCollisionShapes(recursive: true)
        dragHandle.components.set(InputTargetComponent())
        self.addChild(dragHandle)
    }
}

// MARK: - Entityを再帰的に検索するためのヘルパー拡張機能
extension Entity {
    /// 指定された型のすべての子孫エンティティを再帰的に検索する
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
