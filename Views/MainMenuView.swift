import SwiftUI

struct MainMenuView: View {
    @Binding var showAddCardView: Bool
    @Binding var redrawTrigger: Bool
    @ObservedObject var cardStore: CardStore
    
    var onFlipAllToFront: () -> Void = {}
    var onFlipAllToBack: () -> Void = {}

    var body: some View {
        VStack(spacing: 16) {
            Text("登録済みカード数: \(cardStore.cards.count)")
                .font(.title3)
                .fontWeight(.semibold)

            Button("カードを追加") {
                showAddCardView = true
            }
            
            HStack {
                Button("すべて表に") {
                    onFlipAllToFront()
                }
                Button("すべて裏に") {
                    onFlipAllToBack()
                }
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
