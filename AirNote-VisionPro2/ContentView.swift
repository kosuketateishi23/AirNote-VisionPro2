import SwiftUI
import RealityKit

struct ContentView: View {
    // AppModelとImmersiveSpace制御用のEnvironmentを取得
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = false

    var body: some View {
        ZStack {
            // UI要素のみを管理
            VStack {
                Text("AirNote コントロールパネル")
                    .font(.extraLargeTitle2)
                    .fontWeight(.light)
                    .padding(.top, 40)

                Spacer()
                
                // MainMenuViewにはCardStoreのフィルター状態をバインディングで渡す
                MainMenuView(
                    showAddCardView: $showAddCardView,
                    cardStore: cardStore,
                    selectedColorFilters: $cardStore.selectedColorFilters, // CardStoreの状態をバインド
                    onFlipAllToFront: {
                        // ImmersiveViewに「すべて表に」を通知
                        NotificationCenter.default.post(name: .flipAllCards, object: true)
                    },
                    onFlipAllToBack: {
                        // ImmersiveViewに「すべて裏に」を通知
                        NotificationCenter.default.post(name: .flipAllCards, object: false)
                    }
                )
                .frame(maxWidth: 400)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
            }

            // カード追加ビューの表示切り替え
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

            }
        }
        .onAppear {
            // 保存されたカードを読み込む
            cardStore.loadCards()
            
            // ▼▼▼ 変更点 ▼▼▼
            // イマーシブ空間がまだ開かれていなければ、自動で開く
            if appModel.immersiveSpaceState == .closed {
                Task {
                    await openImmersiveSpace(id: appModel.immersiveSpaceID)
                }
            }
        }
    }
}

// ImmersiveViewと通信するためのNotification Name
extension Notification.Name {
    static let flipAllCards = Notification.Name("flipAllCards")
}
