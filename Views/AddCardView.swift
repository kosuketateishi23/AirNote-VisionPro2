import SwiftUI

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var english = ""
    @State private var japanese = ""
    @State private var partOfSpeech = "名詞"
    @State private var memo = ""
    @Binding var redrawTrigger: Bool
    @State private var selectedColor = "beige"
    
    var onDismissTapped: () -> Void = {}

    let partsOfSpeech = ["名詞", "動詞", "形容詞", "副詞", "熟語", "接続詞", "その他"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 🔳 閉じる（削除）ボタン：左上に配置（赤 ×）
            HStack {
                Button(action: {
                    onDismissTapped()
                }) {
                    Text("×")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Spacer()
            }

            TextField("English", text: $english)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)

            TextField("Japanese", text: $japanese)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(partsOfSpeech, id: \.self) { part in
                        Text(part)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(partOfSpeech == part ? Color.brown : Color.gray.opacity(0.2))
                            .foregroundColor(partOfSpeech == part ? .white : .black)
                            .cornerRadius(12)
                            .onTapGesture {
                                partOfSpeech = part
                            }
                    }
                }
                .padding(.horizontal)
            }

            TextField("メモ（例文、語法など）", text: $memo)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)

            HStack(spacing: 12) {
                ForEach(["beige", "pink", "blue", "green", "gray"], id: \.self) { color in
                    Circle()
                        .fill(materialColor(from: color))
                        .frame(width: selectedColor == color ? 36 : 28,
                               height: selectedColor == color ? 36 : 28)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.3),
                                        lineWidth: selectedColor == color ? 2 : 1)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .padding(.top, 10)

            Button("保存") {
                let newCard = Card(
                    english: english,
                    japanese: japanese,
                    partOfSpeech: partOfSpeech,
                    memo: memo,
                    colorName: selectedColor,
                    position: SIMD3<Float>(0, 0, 0),
                    rotation: simd_quatf()
                )
                CardStore.shared.addCard(newCard)
                onDismissTapped()
                print("🟢 カード追加: \(newCard.english)")
                redrawTrigger.toggle()
                dismiss()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .frame(width: 500, height: 480)
        .background(.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear {
            print("🟠 AddCardView 表示")
        }
    }

    func materialColor(from name: String) -> Color {
        switch name {
        case "pink": return Color(red: 1.0, green: 0.92, blue: 0.93)
        case "blue": return Color(red: 0.9, green: 0.95, blue: 1.0)
        case "green": return Color(red: 0.9, green: 1.0, blue: 0.9)
        case "gray": return Color(white: 0.95)
        default: return Color(red: 1.0, green: 0.98, blue: 0.9) // beige
        }
    }
}
