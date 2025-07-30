import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = true
    @State private var redrawTrigger = false
    @State private var draggingCard: ModeledNoteCardEntity? = nil
    
    @State private var cardTemplateEntity: Entity?

    var body: some View {
        ZStack {
            // 🧱 RealityKitの3D空間表示
            RealityView { content in
                if cardTemplateEntity == nil {
                    Task {
                        do {
                            let scene = try await Entity(named: "Scene", in: realityKitContentBundle)
                            self.cardTemplateEntity = scene
                            self.redrawTrigger.toggle()
                        } catch {
                            print("🚨 Reality Composer Proのシーン読み込みに失敗: \(error)")
                        }
                    }
                }
                
                if let cardTemplateEntity {
                    for card in cardStore.cards {
                        let cardEntity = ModeledNoteCardEntity(card: card, sceneTemplate: cardTemplateEntity)
                        cardEntity.position = card.position
                        cardEntity.orientation = card.rotation
                        content.add(cardEntity)
                    }
                }
            }
            .id(redrawTrigger)
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
                                    redrawTrigger.toggle()
                                    return
                                case "dragHandle":
                                    // Implement drag logic later
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
                    cardStore: cardStore
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
                // ▼▼▼ 変更点 ▼▼▼
                // VStackとSpacerを使って、AddCardViewを画面の中央に配置するように変更。
                // これにより、ウィンドウサイズがコンテンツに合わせて自動調整されます。
                VStack {
                    Spacer() // 上の余白
                    
                    AddCardView(redrawTrigger: $redrawTrigger) {
                        showAddCardView = false
                    }
                    .frame(width: 500) // 幅のみ指定

                    Spacer() // 下の余白
                }
                .padding(60) // 画面の端からの余白
                .transition(.opacity)
                .zIndex(999)

            } else {
                // カード追加ボタン（＋）
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
    }
}
