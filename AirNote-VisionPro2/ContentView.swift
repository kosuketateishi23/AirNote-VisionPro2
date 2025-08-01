import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @ObservedObject var cardStore = CardStore.shared
    @State private var showAddCardView = false

    var body: some View {
        ZStack {
            VStack {
                Text("AirNote コントロールパネル")
                    .font(.extraLargeTitle2)
                    .fontWeight(.light)
                    .padding(.top, 40)

                Spacer()
                
                MainMenuView(
                    showAddCardView: $showAddCardView,
                    cardStore: cardStore,
                    selectedColorFilters: $cardStore.selectedColorFilters
                )
                .frame(maxWidth: 400)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding()
            }

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
            cardStore.loadCards()
            
            if appModel.immersiveSpaceState == .closed {
                Task {
                    await openImmersiveSpace(id: appModel.immersiveSpaceID)
                }
            }
        }
    }
}
