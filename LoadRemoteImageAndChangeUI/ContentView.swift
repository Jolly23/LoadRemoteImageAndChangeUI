//
//  ContentView.swift
//  LoadRemoteImageAndChangeUI
//
//  Created by Jolly on 3/15/20.
//  Copyright © 2020 Jolly. All rights reserved.
//

import SwiftUI
import Combine
import Alamofire
import SwiftyJSON
import SocketIO

class MySocket {
    
    let manager = SocketManager(socketURL: URL(string: "https://mock-sio.roostoo.com")!, config: [.log(true), .compress])
    var socket:SocketIOClient!
    
    init() {
        self.socket = manager.defaultSocket
        
        addHandlers()
        socket.connect()
    }
    
    func addHandlers() {
        self.socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.socket.emit("sub", "BCH/USD@DEPTH,BCH/USD@TICKER,BNB/USD@DEPTH,BNB/USD@TICKER,BTC/USD@DEPTH,BTC/USD@TICKER")
        }
        
        self.socket.on(clientEvent: .error) {data, ack in
            print(data)
        }
        
        self.socket.on("message") {data, ack in
            print(data)
            //            guard let cur = data[0] as? Double else { return }
            //            socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
            //                socket.emit("update", ["amount": cur + 2.50])
            //            }
            
            //            ack.with("Got your message", "dude")
        }
    }
}

final class DODODO: ObservableObject {
    @Published var count:Int = 0
    @Published var remoteImage:UIImage?
    @Published var downloadImageBegin:Bool = false
    
    @Published var APIMessage:String = ""
    
    func update() {
        self.count += 1
    }
    
    func reset() {
        self.count = 0
    }
    
    func downloadImage() {
        self.downloadImageBegin = true
        AF.download("https://static.roostoo.com/national-flag/us.png").responseData { response in
            if let data = response.value {
                self.remoteImage = UIImage(data: data)
            }
            
        }
    }
    
    
    
    func setSomethingFromAPI() {
        self.loadJson()
    }
    
    private func loadJson() {
        
        
        var request = URLRequest(url: NSURL.init(string: "https://mock-api.roostoo.com/v1/exchangeInfo")! as URL)
        request.httpMethod = "GET"
        //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval=5
        //        let postString = "param1=\(var1)&param2=\(var2)"
        //        request.httpBody = postString.data(using: .utf8)
        
        
        AF.request(request).response { response in
            switch response.result {
            case .success(let data) :
                if (response.response!.statusCode == 200) {
                    do {
                        let jsonResp = try JSON(data: data!)
                        debugPrint(jsonResp)
                        
                        self.APIMessage = "OK"
                        
                    } catch {
                        self.APIMessage = "Json format error"
                    }
                } else {
                    if let errMessage = String(data: data!, encoding: .utf8) {
                        debugPrint("ErrMessage: \(errMessage)")
                        self.APIMessage = errMessage
                    }
                }
            case .failure(let error) :
                debugPrint("ERROR2: \(error)")
                self.APIMessage = "Network error"
            }
        }
    }
    
    
    
    func getOrders(completionHandler: @escaping (AFDataResponse<Data?>) -> Void) {
        performRequest(completion: completionHandler)
    }
    
    func performRequest(completion: @escaping (AFDataResponse<Data?>) -> Void) {
        
        
        var request = URLRequest(url: NSURL.init(string: "https://mock-api.roostoo.com/v1/exchangeInfo")! as URL)
        request.httpMethod = "GET"
        //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval=5
        //        let postString = "param1=\(var1)&param2=\(var2)"
        //        request.httpBody = postString.data(using: .utf8)
        
        
        AF.request(request).response { response in
            completion(response)
        }
    }
    
    func syncRequest() {
        self.getOrders { result in
            switch result.result {
            case .success(let data) :
                print(1, data)
            case .failure(let error) :
                print(2, error)
            }
        }
    }
    
    
    
    
    
    func isLoadedImage() -> Bool {
        return self.downloadImageBegin
    }
    
    func startSocket() {
        let x = MySocket()
    }
    
}

struct ContentView: View {
    @ObservedObject private var myClass = DODODO()
    
    
    
    var body: some View {
        VStack(spacing: 30) {
            
            if (myClass.remoteImage != nil) {
                Image(uiImage: myClass.remoteImage!)
            } else {
                Image(systemName: "person.2")
            }
            
            Text("\(myClass.count)")
            Text("\(myClass.APIMessage)")
            
            Button(action: {
                self.myClass.update()
            }) {
                Text("CLICK")
                    .font(.largeTitle)
            }
            
            
            
            Button(action: {
                self.myClass.downloadImage()
            }) {
                Text("Load Image")
                    .font(.largeTitle)
            }.disabled(self.myClass.isLoadedImage())
            
            
            Button(action: {
                self.myClass.setSomethingFromAPI()
            }) {
                Text("Load JSON")
                    .font(.largeTitle)
            }
            
            Button(action: {
                self.myClass.startSocket()
            }) {
                Text("Start Socket")
                    .font(.largeTitle)
            }
            
            Button(action: {
                self.myClass.reset()
                self.myClass.remoteImage = nil
                self.myClass.downloadImageBegin = false
                
            }) {
                Text("RESET")
                    .font(.largeTitle)
            }
            
            
            
        }
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
