import SwiftUI

struct MainMenuView: View {
    @Binding var showAddCardView: Bool
    @Binding var redrawTrigger: Bool
    @ObservedObject var cardStore: CardStore  // ✅ 追加

    var body: some View {
        VStack(spacing: 16) {
            Text("登録済みカード数: \(cardStore.cards.count)")  // ✅ ここも修正
                .font(.title3)
                .fontWeight(.semibold)

            Button("カードを追加") {
                print("🟡 カード追加ボタンが押されました")
                showAddCardView = true
            }
            
            Button("全削除") {
                cardStore.clearAllCards()
                redrawTrigger.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
