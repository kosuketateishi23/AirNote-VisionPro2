//
//  CardListView.swift
//  cardtest
//
//  Created by Ayumu Yamamoto on 2025/04/30.
//

import SwiftUI

struct CardListView: View {
    @ObservedObject var cardStore = CardStore.shared

    var body: some View {
        List(cardStore.cards) { card in
            NavigationLink(destination: CardDetailView(card: card)) {
                Text(card.english)
            }
        }
        .navigationTitle("カード一覧")
    }
}
