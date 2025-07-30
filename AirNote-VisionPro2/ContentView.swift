import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = true
    @State private var redrawTrigger = false
    
    @State private var cardEntities: [ModeledNoteCardEntity] = []
    @State private var cardTemplateEntity: Entity?

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
                    content.entities.removeAll()
                    for entity in cardEntities {
                        content.add(entity)
                    }
                }
            )
            .gesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { gesture in
                        var current: Entity? = gesture.entity
                        while let entity = current {
                            if let cardEntity = entity as? ModeledNoteCardEntity {
                                switch gesture.entity.name {
                                case "deleteButton":
                                    cardStore.removeCard(cardEntity.card)
                                    return
                                default:
                                    cardEntity.flip()
                                    return
                                }
                            }
                            current = entity.parent
                        }
                    }
            )

            // 📋 下部メニュー（MainMenuView）
            VStack {
                Spacer()
                MainMenuView(
                    showAddCardView: $showAddCardView,
                    redrawTrigger: $redrawTrigger,
                    cardStore: cardStore,
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
                    
                    AddCardView(redrawTrigger: $redrawTrigger) {
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
        .onChange(of: redrawTrigger) { _, _ in updateCardEntities() }
    }
    
    private func updateCardEntities() {
        guard let cardTemplateEntity else { return }
        
        Task {
            var newEntities: [ModeledNoteCardEntity] = []
            for card in cardStore.cards {
                let cardEntity = ModeledNoteCardEntity(card: card, sceneTemplate: cardTemplateEntity)
                cardEntity.position = card.position
                cardEntity.orientation = card.rotation
                newEntities.append(cardEntity)
            }
            self.cardEntities = newEntities
        }
    }
}
