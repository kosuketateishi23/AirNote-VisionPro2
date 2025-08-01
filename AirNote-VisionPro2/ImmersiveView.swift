//
//  ImmersiveView.swift
//  AirNote-VisionPro2
//
//  Created by Kosuke Tateishi on 2025/07/29.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @ObservedObject var cardStore = CardStore.shared
    @Environment(AppModel.self) private var appModel
    
    @State private var cardEntities: [ModeledNoteCardEntity] = []
    @State private var cardTemplateEntity: Entity?
    @State private var draggedEntity: ModeledNoteCardEntity? = nil

    @State private var arkitSession = ARKitSession()
    @State private var worldTracking = WorldTrackingProvider()
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5.0)
            .targetedToAnyEntity()
            .onChanged { value in
                if self.draggedEntity == nil, let targetEntity = value.entity.findNearestAncestor(ofType: ModeledNoteCardEntity.self) {
                    if value.entity.name != "deleteButton" {
                        self.draggedEntity = targetEntity
                    }
                }
                
                if let draggedEntity = self.draggedEntity {
                    let newPosition = value.convert(value.location3D, from: .local, to: draggedEntity.parent!)
                    draggedEntity.position = newPosition
                }
            }
            .onEnded { value in
                if let draggedEntity = self.draggedEntity, let index = cardStore.cards.firstIndex(where: { $0.id == draggedEntity.card.id }) {
                    cardStore.cards[index].position = draggedEntity.position
                    cardStore.saveCards()
                }
                self.draggedEntity = nil
            }
    }
    
    var tapGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                if self.draggedEntity == nil, let cardEntity = value.entity.findNearestAncestor(ofType: ModeledNoteCardEntity.self) {
                    if value.entity.name == "deleteButton" {
                        cardStore.removeCard(cardEntity.card)
                    } else {
                        cardEntity.flip()
                    }
                }
            }
    }

    private var realityViewContent: some View {
        RealityView(
            make: { content in
                Task {
                    self.cardTemplateEntity = try? await Entity(named: "Scene", in: realityKitContentBundle)
                    updateCardEntities()
                }
            },
            update: { content in
                guard self.draggedEntity == nil else { return }
                
                content.entities.removeAll()
                for entity in cardEntities {
                    content.add(entity)
                }
            }
        )
        .gesture(dragGesture)
        .gesture(tapGesture)
    }
    
    private var viewWithEntityUpdates: some View {
        realityViewContent
            .onChange(of: cardStore.cards) { _, _ in updateCardEntities() }
            .onChange(of: cardStore.selectedColorFilters) { _, _ in updateCardEntities() }
            .onChange(of: cardTemplateEntity) { _, _ in updateCardEntities() }
    }

    var body: some View {
        viewWithEntityUpdates
            .onAppear {
                Task {
                    try? await arkitSession.run([worldTracking])
                }
            }
            .onChange(of: appModel.addCardRequest) { _, newRequest in
                guard let cardData = newRequest else { return }
                handleCardAddition(cardData: cardData)
                appModel.didAddCard()
            }
            .onChange(of: appModel.flipAllRequest) { _, newRequest in
                guard let direction = newRequest else { return }
                let toFront = (direction == .front)
                for entity in cardEntities {
                    entity.flip(toFront: toFront)
                }
                appModel.didFlipAll()
            }
    }
    
    // ▼▼▼ 修正点: 引数の型をAddCardRequestDataに変更 ▼▼▼
    private func handleCardAddition(cardData: AddCardRequestData) {
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        let cameraTransform = deviceAnchor.originFromAnchorTransform
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.5
        let positionTransform = cameraTransform * translation
        
        let position = SIMD3<Float>(positionTransform.columns.3.x, positionTransform.columns.3.y, positionTransform.columns.3.z)
        let rotation = simd_quatf(positionTransform)
        
        // ▼▼▼ 修正点: 構造体のプロパティから値を取得 ▼▼▼
        let newCard = Card(
            english: cardData.english,
            japanese: cardData.japanese,
            partOfSpeech: cardData.partOfSpeech,
            memo: cardData.memo,
            colorName: cardData.colorName,
            position: position,
            rotation: rotation,
            size: cardData.size
        )
        
        CardStore.shared.addCard(newCard)
    }
    
    private func updateCardEntities() {
        guard self.draggedEntity == nil else { return }
        guard let cardTemplateEntity else { return }
        
        Task {
            let cardsToDisplay: [Card]
            if cardStore.selectedColorFilters.isEmpty {
                cardsToDisplay = cardStore.cards
            } else {
                cardsToDisplay = cardStore.cards.filter { cardStore.selectedColorFilters.contains($0.colorName) }
            }
            
            var newEntities: [ModeledNoteCardEntity] = []
            for card in cardsToDisplay {
                let cardEntity = ModeledNoteCardEntity(card: card, sceneTemplate: cardTemplateEntity)
                cardEntity.position = card.position
                cardEntity.orientation = card.rotation
                newEntities.append(cardEntity)
            }

            await MainActor.run {
                self.cardEntities = newEntities
            }
            
            let justAddedEntity = newEntities.first { $0.card.id == CardStore.shared.justAddedCardID }
            CardStore.shared.justAddedCardID = nil
            try? await Task.sleep(for: .milliseconds(10))
            await MainActor.run {
                justAddedEntity?.playStickAnimation()
            }
        }
    }
}

extension Entity {
    func findNearestAncestor<T: Entity>(ofType type: T.Type) -> T? {
        var current: Entity? = self
        while let entity = current {
            if let target = entity as? T {
                return target
            }
            current = entity.parent
        }
        return nil
    }
}
