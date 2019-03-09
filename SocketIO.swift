//
//  SocketIO.swift
//
//  Created by y.k. noaki on 2019/01/31.
//

import Foundation
import SocketIO
class SocketIOManager: NSObject {
    var manager:SocketManager!
    var socketIOClient: SocketIOClient!
    override init(){
        let URLstr: String = "http://[yourURL]:[yourPort]/"
        manager = SocketManager(socketURL: URL(string: URLstr)!, config: [.log(false),.compress])
        socketIOClient = manager.defaultSocket
        
        socketIOClient.on(clientEvent: .connect) {data, ack in
            print(data)
            print("socket connected")
        }
        
        socketIOClient.on(clientEvent: .error) { (data, eck) in
            print(data)
            print("socket error")
        }
        
        socketIOClient.on(clientEvent: .disconnect) { (data, eck) in
            print(data)
            print("socket disconnect")
        }
        
        socketIOClient.on(clientEvent: SocketClientEvent.reconnect) { (data, eck) in
            print(data)
            print("socket reconnect")
        }
        
        
    }
    
    func establishConnection(){
        socketIOClient.connect()
    }
    func closeConnection(){
        socketIOClient.disconnect()
    }
    func joinRoom(roomId: Int){
        socketIOClient.emit("client_to_server_join", String(roomId))
    }
}

