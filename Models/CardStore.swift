import Foundation
import simd
import Combine

class CardStore: ObservableObject {
    static let shared = CardStore()

    @Published var cards: [Card] = []
    
    var justAddedCardID: UUID? = nil

    private let key = "savedCards"

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
