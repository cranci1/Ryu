//
//  LocalServerViewModel.swift
//  Ryu
//
//  Created by Francesco on 12/09/24.
//

import UIKit
import GCDWebServer

struct Repository: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: String
    let port: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Repository, rhs: Repository) -> Bool {
        lhs.id == rhs.id
    }
}

struct TranslationRequest: Codable {
    let text: String
    let sourceLang: String
    let targetLang: String
}

struct TranslationResponse: Codable {
    let code: Int
    let data: String
    let sourceLang: String
    let targetLang: String
    
    enum CodingKeys: String, CodingKey {
        case code, data
        case sourceLang = "source_lang"
        case targetLang = "target_lang"
    }
}

class LocalServerViewModel {
    var repositories: [Repository] = [
        Repository(name: "DeepLX vercel", url: "https://github.com/bropines/Deeplx-vercel.git", port: 9000)
    ]
    var selectedRepository: Repository?
    var isProcessing = false
    var serverResponse: String = ""
    
    private var webServer: GCDWebServer?
    
    var onUpdate: ((String) -> Void)?
    var onProcessFinished: (() -> Void)?
    
    func startProcess() {
        guard let repository = selectedRepository else { return }
        isProcessing = true
        serverResponse = "Starting process..."
        onUpdate?(serverResponse)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.cloneRepository(repository)
        }
    }
    
    private func cloneRepository(_ repository: Repository) {
        serverResponse += "\nCloning repository: \(repository.name)..."
        onUpdate?(serverResponse)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startServer(repository)
        }
    }
    
    private func startServer(_ repository: Repository) {
        serverResponse += "\nStarting local server on port \(repository.port)..."
        onUpdate?(serverResponse)
        
        webServer = GCDWebServer()
        
        webServer?.addHandler(forMethod: "POST", path: "/api/translate", request: GCDWebServerDataRequest.self) { [weak self] (request, completion) in
            guard let dataRequest = request as? GCDWebServerDataRequest else {
                completion(GCDWebServerDataResponse(statusCode: 400))
                return
            }
            
            do {
                let translationRequest = try JSONDecoder().decode(TranslationRequest.self, from: dataRequest.data)
                let translatedText = "Ciao amico mio"
                let response = TranslationResponse(code: 200, data: translatedText, sourceLang: "auto", targetLang: "it")
                let jsonData = try JSONEncoder().encode(response)
                
                let dataResponse = GCDWebServerDataResponse(data: jsonData, contentType: "application/json")
                completion(dataResponse)
                
                DispatchQueue.main.async {
                    self?.serverResponse += "\nReceived translation request: \(translationRequest.text)"
                    self?.serverResponse += "\nResponded with: \(translatedText)"
                    self?.onUpdate?(self?.serverResponse ?? "")
                }
            } catch {
                completion(GCDWebServerDataResponse(statusCode: 400))
            }
        }
        
        do {
            try webServer?.start(options: [GCDWebServerOption_Port: repository.port])
            serverResponse += "\nServer started successfully"
            onUpdate?(serverResponse)
            makeTranslationRequest(repository)
        } catch {
            serverResponse += "\nFailed to start server: \(error.localizedDescription)"
            isProcessing = false
            onUpdate?(serverResponse)
            onProcessFinished?()
        }
    }
    
    private func makeTranslationRequest(_ repository: Repository) {
        serverResponse += "\nMaking translation request to http://localhost:\(repository.port)/api/translate..."
        onUpdate?(serverResponse)
        
        let url = URL(string: "http://localhost:\(repository.port)/api/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = TranslationRequest(text: "Hola amigo", sourceLang: "auto", targetLang: "it")
        request.httpBody = try? JSONEncoder().encode(payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.serverResponse += "\nError: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    self?.serverResponse += "\nStatus code: \(httpResponse.statusCode)"
                    if let data = data,
                       let json = try? JSONDecoder().decode(TranslationResponse.self, from: data) {
                        self?.serverResponse += "\nTranslated text: \(json.data)"
                    }
                }
                self?.isProcessing = false
                self?.onUpdate?(self?.serverResponse ?? "")
                self?.onProcessFinished?()
            }
        }.resume()
    }
}
