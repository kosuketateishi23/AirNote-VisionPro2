import SwiftUI
import RealityKit

// 🧩 アプリのメインビュー
struct ContentView: View {
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = true  // ✅ カード追加ビューの表示制御
    @State private var redrawTrigger = false   // ✅ RealityViewの再描画トリガー
    @State private var draggingCard: NoteCardEntity? = nil  // ✅ 移動中のカードを保持

    var body: some View {
        ZStack {
            // 🧱 RealityKitの3D空間表示
            RealityView { content in
                content.entities.removeAll()

                for card in cardStore.cards {
                    print("🔁 描画対象カード: \(card.english)")
                    let cardEntity = NoteCardEntity(card: card)
                    cardEntity.position = card.position
                    cardEntity.orientation = card.rotation
                    content.add(cardEntity)

                    if draggingCard?.card.id == card.id {
                        draggingCard = cardEntity
                    }
                }
            }
            .id(redrawTrigger) // ✅ redrawTriggerが変化するとRealityViewを再生成
            // 👆 RealityViewにタップジェスチャを追加
            .gesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { gesture in
                        var current: Entity? = gesture.entity

                        while let entity = current {
                            switch entity.name {
                            case "deleteButton":
                                // 🗑 削除ボタンが押された場合
                                if let cardEntity = sequence(first: entity, next: { $0.parent })
                                    .first(where: { $0 is NoteCardEntity }) as? NoteCardEntity {
                                    cardStore.removeCard(cardEntity.card)
                                    redrawTrigger.toggle()  // ✅ カードを再描画
                                    print("🗑 削除: \(cardEntity.card.english)")
                                    return
                                }

                            case "dragHandle":
                                // 📌 移動バーが押された場合（カードを前方に移動）
                                if let cardEntity = sequence(first: entity, next: { $0.parent })
                                    .first(where: { $0 is NoteCardEntity }) as? NoteCardEntity {
                                    draggingCard = cardEntity
                                    cardEntity.position = SIMD3<Float>(0, 0, -0.5)
                                    print("📌 移動開始: \(cardEntity.card.english)")
                                    return
                                }

                            default:
                                break
                            }

                            current = entity.parent
                        }

                        // 🔄 通常タップ（カードの表裏を反転）
                        if let cardEntity = gesture.entity.parent?.parent as? NoteCardEntity {
                            cardEntity.flip()
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
        // 📥 アプリ起動時にカードを読み込み
        .onAppear {
            cardStore.loadCards()
        }
        // 🔁 カード移動後、位置保存と再描画
        .onChange(of: draggingCard) { newCard in
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
