import SwiftUI

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppModel.self) private var appModel
    
    @State private var english = ""
    @State private var japanese = ""
    @State private var partOfSpeech = "名詞"
    @State private var memo = ""
    @State private var selectedColor = "beige"
    @State private var selectedSize = "大"
    
    var onDismissTapped: () -> Void = {}

    let partsOfSpeech = ["名詞", "動詞", "形容詞", "副詞", "熟語", "接続詞", "その他"]
    let sizes = ["小", "中", "大"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            // ▼▼▼ 変更: プレースホルダーをカスタマイズ ▼▼▼
            ZStack(alignment: .leading) {
                if english.isEmpty {
                    Text("    English")
                        .foregroundColor(.black.opacity(0.2))
                }
                TextField("", text: $english)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.black)
            }

            ZStack(alignment: .leading) {
                if japanese.isEmpty {
                    Text("    Japanese")
                        .foregroundColor(.black.opacity(0.2))
                }
                TextField("", text: $japanese)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.black)
            }
            // ▲▲▲ ここまで変更 ▲▲▲

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
                            .hoverEffect()
                            .onTapGesture {
                                partOfSpeech = part
                            }
                    }
                }
                .padding(.horizontal)
            }

            // ▼▼▼ 変更: プレースホルダーをカスタマイズ ▼▼▼
            ZStack(alignment: .leading) {
                if memo.isEmpty {
                    Text("    メモ（例文、語法など）")
                        .foregroundColor(.black.opacity(0.2))
                }
                TextField("", text: $memo)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(.black)
            }
            // ▲▲▲ ここまで変更 ▲▲▲

            // ▼▼▼ 変更: 文字色を黒に指定 ▼▼▼
            Text("サイズ")
                .font(.headline)
                .padding(.leading)
                .foregroundColor(.black)
            // ▲▲▲ ここまで変更 ▲▲▲
            
            HStack(spacing: 12) {
                ForEach(sizes, id: \.self) { size in
                    Text(size)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedSize == size ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundColor(selectedSize == size ? .white : .black)
                        .cornerRadius(12)
                        .hoverEffect()
                        .onTapGesture {
                            selectedSize = size
                        }
                }
            }
            .padding(.horizontal)
            
            Text("色")
                .font(.headline)
                .padding(.leading)
                .foregroundColor(.black)
            
            HStack(spacing: 12) {
                ForEach(["beige", "pink", "blue", "green", "gray"], id: \.self) { color in
                    Button(action: {
                                selectedColor = color
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(materialColor(from: color))
                                    Circle()
                                        .stroke(Color.black.opacity(0.3),
                                                lineWidth: selectedColor == color ? 2 : 1)
                                }
                                .frame(width: selectedColor == color ? 36 : 28,
                                       height: selectedColor == color ? 36 : 28)
                            }
                            .buttonStyle(.plain)
                            .hoverEffect()
                }
            }
            .padding(.top, 10)

            Button(action: {
                let cardData = AddCardRequestData(
                    english: english,
                    japanese: japanese,
                    partOfSpeech: partOfSpeech,
                    memo: memo,
                    colorName: selectedColor,
                    size: selectedSize
                )
                appModel.requestAddCard(data: cardData)
                onDismissTapped()
            }) {
                Text("保存")
                    .foregroundColor(.black.opacity(0.8))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(radius: 10)
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
