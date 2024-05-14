//
//  OrderBook.swift
//  Coin
//
//  Created by 조유진 on 5/15/24.
//

import Foundation

struct OrderBook: Hashable, Decodable {
    let timestamp: Int
    let total_ask_size: Double
    let total_bid_size: Double
    let orderbook_units: [OrderBookUnit]
}

struct OrderBookUnit: Hashable, Decodable {
    let ask_price, ask_size: Double
    let bid_price, bid_size: Double
}

// 서버에서 받은 디코딩 데이터를 다시 뷰에 표현해주기 위해 정렬할 모델
struct OrderBookItem: Hashable, Identifiable {
    let id = UUID()
    let price: Double
    let size: Double
}
