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

    // ▼▼▼ 追加 ▼▼▼
    // 回転操作の対象エンティティと、操作開始時の向きを保持するState
    @State private var rotatingEntity: ModeledNoteCardEntity? = nil
    @State private var initialRotation: simd_quatf? = nil
    // ▲▲▲ 追加 ▲▲▲

    @State private var arkitSession = ARKitSession()
    @State private var worldTracking = WorldTrackingProvider()
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5.0)
            .targetedToAnyEntity()
            .onChanged { value in
                // ▼▼▼ 変更 ▼▼▼
                // 回転操作中はドラッグを無効にする
                guard self.rotatingEntity == nil else { return }
                
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
                // ▼▼▼ 変更 ▼▼▼
                // ドラッグ中や回転中はタップを無効にする
                guard self.draggedEntity == nil, self.rotatingEntity == nil else { return }
                
                if let cardEntity = value.entity.findNearestAncestor(ofType: ModeledNoteCardEntity.self) {
                    if value.entity.name == "deleteButton" {
                        cardStore.removeCard(cardEntity.card)
                    } else {
                        cardEntity.flip()
                    }
                }
            }
    }
    
    // ▼▼▼ 追加 ▼▼▼
    /// ピンチ＆ツイストによる回転ジェスチャーの定義
    var rotateGesture: some Gesture {
        RotateGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                // ドラッグ中は回転を無効にする
                guard self.draggedEntity == nil else { return }

                // 操作対象のエンティティがまだ設定されていなければ設定
                if self.rotatingEntity == nil {
                    // value.entityから一番近いカードエンティティを探す
                    if let targetEntity = value.entity.findNearestAncestor(ofType: ModeledNoteCardEntity.self) {
                        self.rotatingEntity = targetEntity
                        // 操作開始時の向きを保存
                        self.initialRotation = targetEntity.orientation
                    }
                }

                // 対象エンティティと開始時の向きが取得できていれば、回転処理を実行
                if let rotatingEntity = self.rotatingEntity, let initialRotation = self.initialRotation {
                    // Y軸（縦軸）回りの回転を計算
                    let rotation = simd_quatf(angle: Float(value.rotation.radians), axis: [0, 1, 0])
                    // 開始時の向きに、ジェスチャーによる回転を乗算して、新しい向きを決定
                    let newOrientation = initialRotation * rotation
                    rotatingEntity.orientation = newOrientation
                }
            }
            .onEnded { value in
                // 操作終了時、最終的な向きを計算して保存
                if let rotatingEntity = self.rotatingEntity,
                   let initialRotation = self.initialRotation,
                   let index = cardStore.cards.firstIndex(where: { $0.id == rotatingEntity.card.id }) {
                    
                    let rotation = simd_quatf(angle: Float(value.rotation.radians), axis: [0, 1, 0])
                    let finalOrientation = initialRotation * rotation
                    
                    // CardStoreのデータを更新し、永続化
                    cardStore.cards[index].rotation = finalOrientation
                    cardStore.saveCards()
                }

                // Stateをリセット
                self.rotatingEntity = nil
                self.initialRotation = nil
            }
    }
    // ▲▲▲ 追加 ▲▲▲

    private var realityViewContent: some View {
        RealityView(
            make: { content in
                Task {
                    self.cardTemplateEntity = try? await Entity(named: "Scene", in: realityKitContentBundle)
                    updateCardEntities()
                }
            },
            update: { content in
                // ▼▼▼ 変更 ▼▼▼
                // ドラッグ中・回転中はアップデートをスキップ
                guard self.draggedEntity == nil, self.rotatingEntity == nil else { return }
                
                content.entities.removeAll()
                for entity in cardEntities {
                    content.add(entity)
                }
            }
        )
        // ▼▼▼ 変更 ▼▼▼
        // 3つのジェスチャーを同時に認識できるように設定
        .gesture(SimultaneousGesture(dragGesture, SimultaneousGesture(tapGesture, rotateGesture)))
        // ▲▲▲ 変更 ▲▲▲
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
        // ▼▼▼ 変更 ▼▼▼
        // ドラッグ中・回転中はアップデートをスキップ
        guard self.draggedEntity == nil, self.rotatingEntity == nil else { return }
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
