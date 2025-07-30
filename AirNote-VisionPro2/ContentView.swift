import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = true
    @State private var redrawTrigger = false
    @State private var draggingCard: ModeledNoteCardEntity? = nil
    
    // Reality Composer Proから読み込んだシーンを保持するState
    @State private var cardTemplateEntity: Entity?

    var body: some View {
        ZStack {
            // 🧱 RealityKitの3D空間表示
            RealityView { content in
                // 最初に一度だけ、テンプレートとなるシーンを読み込む
                if cardTemplateEntity == nil {
                    Task {
                        do {
                            let scene = try await Entity(named: "Scene", in: realityKitContentBundle)
                            self.cardTemplateEntity = scene
                            // 読み込み完了後、再描画をトリガー
                            redrawTrigger.toggle()
                        } catch {
                            print("🚨 Reality Composer Proのシーン読み込みに失敗: \(error)")
                        }
                    }
                }
                
                // テンプレートが読み込めていればカードを生成
                if let cardTemplateEntity {
                    content.entities.removeAll()

                    for card in cardStore.cards {
                        print("🔁 描画対象カード: \(card.english)")
                        // 新しいModeledNoteCardEntityを使用
                        let cardEntity = ModeledNoteCardEntity(card: card, sceneTemplate: cardTemplateEntity)
                        cardEntity.position = card.position
                        cardEntity.orientation = card.rotation
                        content.add(cardEntity)

                        if draggingCard?.card.id == card.id {
                            draggingCard = cardEntity
                        }
                    }
                }
            }
            .id(redrawTrigger)
            .gesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { gesture in
                        var current: Entity? = gesture.entity

                        // タップされたエンティティ階層を遡って処理を決定
                        while let entity = current {
                            if let cardEntity = entity as? ModeledNoteCardEntity {
                                switch gesture.entity.name {
                                case "deleteButton":
                                    cardStore.removeCard(cardEntity.card)
                                    redrawTrigger.toggle()
                                    print("🗑 削除: \(cardEntity.card.english)")
                                    return
                                case "dragHandle":
                                    draggingCard = cardEntity
                                    cardEntity.position = SIMD3<Float>(0, 0, -0.5)
                                    print("📌 移動開始: \(cardEntity.card.english)")
                                    return
                                default:
                                    // ボタンやハンドル以外（モデル本体）がタップされた場合
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
                VStack(alignment: .trailing) {
                    AddCardView(redrawTrigger: $redrawTrigger) {
                        showAddCardView = false
                    }
                    .frame(width: 500, height: 480)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
                .padding()
                .zIndex(999)
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddCardView = true
                        }) {
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
        .onChange(of: draggingCard) { _, newCard in
            if let card = newCard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let index = cardStore.cards.firstIndex(where: { $0.id == card.card.id }) {
                        cardStore.cards[index].position = card.position
                        cardStore.saveCards()
                        print("✅ 移動確定: \(card.card.english)")
                        draggingCard = nil
                        redrawTrigger.toggle()
                    }
                }
            }
        }
    }
}
