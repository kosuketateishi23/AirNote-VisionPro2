//
//  AppModel.swift
//  AirNote-VisionPro2
//
//  Created by Kosuke Tateishi on 2025/07/29.
//

import SwiftUI

// ▼▼▼ 修正点 1: [String: Any]の代わりに専用の構造体を定義 ▼▼▼
struct AddCardRequestData: Equatable {
    let english: String
    let japanese: String
    let partOfSpeech: String
    let memo: String
    let colorName: String
    let size: String
}

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // ▼▼▼ 修正点 2: プロパティの型を新しい構造体に変更 ▼▼▼
    var addCardRequest: AddCardRequestData? = nil

    // カード一括反転リクエストを保持するプロパティ
    enum FlipDirection { case front, back }
    var flipAllRequest: FlipDirection? = nil

    /// Viewからカード追加をリクエストするためのメソッド
    // ▼▼▼ 修正点 3: メソッドの引数の型も変更 ▼▼▼
    func requestAddCard(data: AddCardRequestData) {
        self.addCardRequest = data
    }
    
    /// ImmersiveViewがカード追加処理を完了した後に呼ぶメソッド
    func didAddCard() {
        self.addCardRequest = nil
    }

    /// Viewからカードの一括反転をリクエストするためのメソッド
    func requestFlipAll(toFront: Bool) {
        self.flipAllRequest = toFront ? .front : .back
    }
    
    /// ImmersiveViewが一括反転を完了した後に呼ぶメソッド
    func didFlipAll() {
        self.flipAllRequest = nil
    }
}
