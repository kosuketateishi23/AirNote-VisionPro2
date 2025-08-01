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

    var body: some View {
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
        .onChange(of: cardStore.cards) { _, _ in updateCardEntities() }
        .onChange(of: cardStore.selectedColorFilters) { _, _ in updateCardEntities() }
        .onChange(of: cardTemplateEntity) { _, _ in updateCardEntities() }
        .onReceive(NotificationCenter.default.publisher(for: .flipAllCards)) { notification in
            guard let toFront = notification.object as? Bool else { return }
            for entity in cardEntities {
                entity.flip(toFront: toFront)
            }
        }
        .onAppear {
            Task {
                try? await arkitSession.run([worldTracking])
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addCardRequested)) { notification in
            handleCardAddition(notification: notification)
        }
    }
    
    private func handleCardAddition(notification: Notification) {
        guard let cardData = notification.object as? [String: Any],
              let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            return
        }
        
        // ▼▼▼ 修正点 1: 正式なプロパティ名を使用 ▼▼▼
        let cameraTransform = deviceAnchor.originFromAnchorTransform
        
        // 視点の1.5m前方にカードを配置する座標を計算
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.5 // 1.5m奥へ
        let positionTransform = cameraTransform * translation
        
        let position = SIMD3<Float>(positionTransform.columns.3.x, positionTransform.columns.3.y, positionTransform.columns.3.z)
        // ▼▼▼ 修正点 2: 引数ラベル 'from:' を削除 ▼▼▼
        let rotation = simd_quatf(positionTransform)
        
        let newCard = Card(
            english: cardData["english"] as? String ?? "",
            japanese: cardData["japanese"] as? String ?? "",
            partOfSpeech: cardData["partOfSpeech"] as? String ?? "",
            memo: cardData["memo"] as? String ?? "",
            colorName: cardData["colorName"] as? String ?? "beige",
            position: position,
            rotation: rotation,
            size: cardData["size"] as? String ?? "大"
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
