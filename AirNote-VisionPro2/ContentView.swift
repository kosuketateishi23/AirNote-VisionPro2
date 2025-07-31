import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = true
    
    @State private var cardEntities: [ModeledNoteCardEntity] = []
    @State private var cardTemplateEntity: Entity?
    @State private var selectedColorFilters: [String] = []
    
    // ▼▼▼ 変更点 ▼▼▼
    // ドラッグ中のエンティティを保持するStateのみでOK
    @State private var draggedEntity: ModeledNoteCardEntity? = nil

    // ジェスチャーの定義
    var cardGesture: some Gesture {
        // ▼▼▼ 変更点 ▼▼▼
        // DragGestureからEntityTargetValueGestureに変更
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                // ドラッグ中でなければタップを処理
                if let cardEntity = value.entity.findNearestAncestor(ofType: ModeledNoteCardEntity.self) {
                    if value.entity.name == "deleteButton" {
                        cardStore.removeCard(cardEntity.card)
                    } else {
                        cardEntity.flip()
                    }
                }
            }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                // ドラッグ中のエンティティを特定
                if self.draggedEntity == nil, let targetEntity = value.entity.findNearestAncestor(ofType: ModeledNoteCardEntity.self) {
                    if value.entity.name != "deleteButton" {
                        self.draggedEntity = targetEntity
                    }
                }
                
                if let draggedEntity = self.draggedEntity {
                    // ドラッグジェスチャーの位置をエンティティの位置に変換
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

    var body: some View {
        ZStack {
            // 🧱 RealityKitの3D空間表示
            RealityView(
                make: { content in
                    Task {
                        self.cardTemplateEntity = try? await Entity(named: "Scene", in: realityKitContentBundle)
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
            .gesture(cardGesture)

            // 📋 下部メニュー（MainMenuView）
            VStack {
                Spacer()
                MainMenuView(
                    showAddCardView: $showAddCardView,
                    cardStore: cardStore,
                    selectedColorFilters: $selectedColorFilters,
                    onFlipAllToFront: {
                        for entity in cardEntities {
                            entity.flip(toFront: true)
                        }
                    },
                    onFlipAllToBack: {
                        for entity in cardEntities {
                            entity.flip(toFront: false)
                        }
                    }
                )
                .frame(maxWidth: 400)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
                .zIndex(500)
            }

            // ➕ カード追加ビューの表示切り替え
            if showAddCardView {
                VStack {
                    Spacer()
                    AddCardView() {
                        showAddCardView = false
                    }
                    .frame(width: 500)
                    Spacer()
                }
                .padding(60)
                .transition(.opacity)
                .zIndex(999)

            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddCardView = true }) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.green)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
                .zIndex(1000)
            }
        }
        .onAppear {
            cardStore.loadCards()
        }
        .onChange(of: cardStore.cards) { _, _ in updateCardEntities() }
        .onChange(of: cardTemplateEntity) { _, _ in updateCardEntities() }
        .onChange(of: selectedColorFilters) { _, _ in updateCardEntities() }
    }
    
    private func updateCardEntities() {
        guard self.draggedEntity == nil else { return }
        guard let cardTemplateEntity else { return }
        
        Task {
            let cardsToDisplay: [Card]
            if selectedColorFilters.isEmpty {
                cardsToDisplay = cardStore.cards
            } else {
                cardsToDisplay = cardStore.cards.filter { selectedColorFilters.contains($0.colorName) }
            }
            
            var newEntities: [ModeledNoteCardEntity] = []
            for card in cardsToDisplay {
                let cardEntity = ModeledNoteCardEntity(card: card, sceneTemplate: cardTemplateEntity)
                cardEntity.position = card.position
                cardEntity.orientation = card.rotation
                newEntities.append(cardEntity)
            }

            let justAddedEntity = newEntities.first { $0.card.id == CardStore.shared.justAddedCardID }
            self.cardEntities = newEntities
            CardStore.shared.justAddedCardID = nil
            
            try? await Task.sleep(for: .milliseconds(10))
            
            await MainActor.run {
                justAddedEntity?.playStickAnimation()
            }
        }
    }
}

// Entityの親を辿るためのヘルパー関数
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
