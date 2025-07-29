import SwiftUI
import RealityKit

struct CardDetailView: View {
    let card: Card
    @State private var flipEntity: Entity?

    var body: some View {
        VStack {
            Spacer()

            RealityView { content in
                if let flipEntity = try? await Entity(named: "flip", in: .main) {
                    print("✅ flip entity loaded: \(flipEntity)")
                    print("🌀 availableAnimations = \(flipEntity.availableAnimations.map { $0.name })")

                    content.add(flipEntity)
                } else {
                    print("❌ 'flip' entity not found in FlipScene.reality")
                }
            }
            .gesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { gesture in
                        if let animation = gesture.entity.availableAnimations.first {
                            gesture.entity.playAnimation(animation.repeat(count: 1), transitionDuration: 0.3)
                        }
                    }
            )
            .frame(width: 320, height: 180)

            Spacer()
        }
        .navigationTitle("単語カード")
    }
}

struct CardBackView: View {
    let card: Card

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(red: 1.0, green: 0.98, blue: 0.9))
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(card.english)
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text(card.partOfSpeech)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Text(card.japanese)
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)

                    if !card.memo.isEmpty {
                        Text(card.memo)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .font(.subheadline)
                    }
                }
                .padding()
            )
            .shadow(radius: 6)
    }
}
