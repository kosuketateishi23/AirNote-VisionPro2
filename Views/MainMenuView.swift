import SwiftUI

struct MainMenuView: View {
    @Binding var showAddCardView: Bool
    @ObservedObject var cardStore: CardStore
    @Binding var selectedColorFilters: [String]
    
    var onFlipAllToFront: () -> Void = {}
    var onFlipAllToBack: () -> Void = {}

    private let colors = ["beige", "pink", "blue", "green", "gray"]

    var body: some View {
        VStack(spacing: 16) {
            Text("カラーフィルター").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button(action: {
                    selectedColorFilters.removeAll()
                }) {
                    Text("全色")
                        .font(.caption)
                        .fontWeight(selectedColorFilters.isEmpty ? .bold : .regular)
                        .padding(8)
                        .background(selectedColorFilters.isEmpty ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundColor(selectedColorFilters.isEmpty ? .white : .primary)
                        .cornerRadius(8)
                }

                ForEach(colors, id: \.self) { color in
                    let isSelected = selectedColorFilters.contains(color)
                    
                    Circle()
                        .fill(materialColor(from: color))
                        .frame(width: 28, height: 28)
                        .overlay(
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.8), lineWidth: 4)
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.primary)
                                }
                            }
                        )
                        .onTapGesture {
                            if isSelected {
                                selectedColorFilters.removeAll { $0 == color }
                            } else {
                                selectedColorFilters.append(color)
                            }
                        }
                }
            }
            
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
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func materialColor(from name: String) -> Color {
        switch name {
        case "pink": return Color(red: 1.0, green: 0.92, blue: 0.93)
        case "blue": return Color(red: 0.9, green: 0.95, blue: 1.0)
        case "green": return Color(red: 0.9, green: 1.0, blue: 0.9)
        case "gray": return Color(white: 0.95)
        default: return Color(red: 1.0, green: 0.98, blue: 0.9) // beige
        }
    }
}
