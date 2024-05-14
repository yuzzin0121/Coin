//
//  WebSocketManager.swift
//  Coin
//
//  Created by 조유진 on 5/15/24.
//

import Foundation
import Combine

final class WebSocketManager: NSObject {
    static let shared = WebSocketManager()
    
    private var websocket: URLSessionWebSocketTask?
    private var isOpen = false
    
    var orderbookSubject = PassthroughSubject<OrderBook, Never>()
    var timer: Timer?
    
    // 소켓 열기
    func openWebSocket() {
        if let url = URL(string: "wss://api.upbit.com/websocket/v1") {
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            websocket = session.webSocketTask(with: url)
            websocket?.resume()
        }
    }
    
    // 소켓 닫기
    func closeWebSocket() {
        websocket?.cancel(with: .goingAway, reason: nil)
        websocket = nil
        
        timer?.invalidate()
        timer = nil
        
        isOpen = false
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    // 소켓이 열렸을 떄
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Socket Open")
        isOpen = true
        receiveSocketData() // 소켓을 통해 데이터 받기
    }
    
    // 소켓이 닫혔을 때
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Socket Closed")
        isOpen = false
    }
}

extension WebSocketManager {
    // 소켓에 필요한 데이터 요청 보내기
    func send(_ string: String) {
        websocket?.send(URLSessionWebSocketTask.Message.string(string), completionHandler: { error in
            print("Send Error")
        })
    }
    
    // 재귀적인 구조로 구성이 되어야 계속해서 데이터를 수신할 수 있다.
    func receiveSocketData() {
        if isOpen {
            websocket?.receive(completionHandler: { result in
                switch result {
                case .success(let success):
                    switch success {
                    case .data(let data):
                        if let decodedData = try? JSONDecoder().decode(OrderBook.self, from: data) {
                            dump(decodedData)
                            
                            self.orderbookSubject.send(decodedData)
                        }
                    case .string(let string): print(string)
                    @unknown default:
                        print("Unknown Default")
                    }
                case .failure(let failure):
                    print(failure)
                }
                self.receiveSocketData()    // 재귀 호출
            })
        }
    }
}

extension WebSocketManager {
    // 서버에 의해 연결이 끊어지지 않도록 주기적으로 ping을 서버에 보내주는 작업
    func ping() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _  in
            self?.websocket?.sendPing(pongReceiveHandler: { error in
                if let error = error {
                    print("ping pong error", error.localizedDescription)
                } else {
                    print("ping ping ping")
                }
            })
        }
    }
}
