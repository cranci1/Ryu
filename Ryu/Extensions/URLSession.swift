//
//  URLSession.swift
//  Ryu
//
//  Created by Francesco on 07/12/24.
//

import Foundation

extension URLSession {
    func syncRequest(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = self.dataTask(with: request) { (responseData, urlResponse, responseError) in
            data = responseData
            response = urlResponse
            error = responseError
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return (data, response, error)
    }
}
