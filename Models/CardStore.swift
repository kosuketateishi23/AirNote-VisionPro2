//
//  CardStore.swift
//  AirNote-VisionPro2
//
//  Created by Kosuke Tateishi on 2025/07/29.
//

import Foundation
import simd
import Combine

class CardStore: ObservableObject {
    static let shared = CardStore()

    @Published var cards: [Card] = []
    @Published var selectedColorFilters: [String] = []
    
    var justAddedCardID: UUID? = nil

    private let key = "savedCards"

    // ▼▼▼ 変更点 ▼▼▼
    // 固定座標を設定するロジックを削除し、渡されたcardをそのまま追加する
    func addCard(_ card: Card) {
        cards.append(card)
        justAddedCardID = card.id
        saveCards()
    }

    func removeCard(_ card: Card) {
        cards.removeAll { $0.id == card.id }
        saveCards()
    }

    func saveCards() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cards) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadCards() {
        if let data = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            if let loadedCards = try? decoder.decode([Card].self, from: data) {
                self.cards = loadedCards
            }
        }
    }
    
    func clearAllCards() {
        cards.removeAll()
        saveCards()
    }
}
