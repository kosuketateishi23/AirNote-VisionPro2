//
//  ImmersiveView.swift
//  AirNote-VisionPro2
//
//  Created by Kosuke Tateishi on 2025/07/29.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @ObservedObject var cardStore = CardStore.shared
    
    @State private var cardEntities: [ModeledNoteCardEntity] = []
    @State private var cardTemplateEntity: Entity?
    @State private var draggedEntity: ModeledNoteCardEntity? = nil

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
