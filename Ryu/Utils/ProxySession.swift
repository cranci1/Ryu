//
//  ProxySession.swift
//  Ryu
//
//  Created by Francesco on 08/12/24.
//

import Foundation
import Alamofire

class proxySession {
    static func createAlamofireProxySession() -> Session {
        print("Using Proxy")
        guard let proxyIP = UserDefaults.standard.string(forKey: "ProxyIP"),
              let proxyPortString = UserDefaults.standard.string(forKey: "ProxyPort"),
              let proxyPort = Int(proxyPortString),
              !proxyIP.isEmpty else {
                  return AF
              }
        
        let configuration = URLSessionConfiguration.default
        configuration.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable: true,
            kCFNetworkProxiesHTTPProxy: proxyIP,
            kCFNetworkProxiesHTTPPort: proxyPort
        ]
        
        return Session(configuration: configuration)
    }
}
