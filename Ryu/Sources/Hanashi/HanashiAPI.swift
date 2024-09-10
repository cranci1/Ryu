//
//  HanashiAPI.swift
//  Ryu
//
//  Created by Francesco on 10/09/24.
//

import Foundation
import Alamofire

struct HanashiResponse: Codable {
    let createdAt: String
    let type: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case createdAt
        case type
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

class HanashiAPI {
    static func getHanashiToken(refreshToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = "https://api.hanashi.to/api/session/"
        let parameters: [String: Any] = ["refresh_token": refreshToken]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: HanashiResponse.self) { response in
                switch response.result {
                case .success(let hanashiResponse):
                    completion(.success(hanashiResponse.accessToken))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
