//
//  NetworkingInterface.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation


protocol NetworkingInterface {
    
    var url: URL { get }
    
    var env: NetworkingEnvironment { get }
    
    var session: URLSession { get }
    
    func data(forRequest request: URLRequest, session: URLSession) async throws -> (Data, URLResponse)
    
    func applyDefaultHeaders(request: inout URLRequest) throws
    
    func process(httpResponse response: (Data, URLResponse)) throws -> Data
}


extension NetworkingInterface {
    func data(forRequest request: URLRequest, session: URLSession) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { p_data, p_response, p_error in
                guard let data = p_data, let response = p_response else {
                    guard let error = p_error else {
                        continuation.resume(throwing: NetworkingError.badResponse)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                let returnTuple: (Data, URLResponse) = (data, response)
                continuation.resume(returning: returnTuple)
            }
            task.resume()
        }
    }
    
    func applyDefaultHeaders(request: inout URLRequest) throws {
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
    }
    
    func process(httpResponse response: (Data, URLResponse)) throws -> Data {
        guard let httpResponse = response.1 as? HTTPURLResponse else {
            throw NetworkingError.badResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return response.0
        default:
            print(try JSONSerialization.jsonObject(with: response.0))
            throw NetworkingError.badStatusCode(code: httpResponse.statusCode, data: response.0)
        }
    }
}
