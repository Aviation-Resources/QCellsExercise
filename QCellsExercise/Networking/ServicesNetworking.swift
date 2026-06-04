//
//  ServicesNetworking.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation


class ServicesNetworking: NetworkingInterface {
    
    let url: URL
    
    let env: NetworkingEnvironment
    
    let session: URLSession = URLSession.shared
    
    init(env: NetworkingEnvironment) throws {
        self.env = env
        guard let url = env.apiURL else {
            throw NetworkingError.badURL
        }
        self.url = url
    }
    
    public func post<I: Encodable>(encodableObject object: I?, route: AVServicesRoute) async throws -> Data {
        let finalURL = url.appendingPathComponent(route.route)
        let objectData = try JSONEncoder().encode(object)
        var request: URLRequest = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.httpBody = objectData
        try applyDefaultHeaders(request: &request)
        let response = try await data(forRequest: request, session: session)
        return try process(httpResponse: response)
    }
    
    
    public func post(route: AVServicesRoute) async throws -> Data {
        let finalURL = url.appendingPathComponent(route.route)
        var request: URLRequest = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        try applyDefaultHeaders(request: &request)
        let response = try await data(forRequest: request, session: session)
        return try process(httpResponse: response)
    }
    
    public func delete(route: AVServicesRoute) async throws -> Data {
        let finalURL = url.appendingPathComponent(route.route)
        var request: URLRequest = URLRequest(url: finalURL)
        request.httpMethod = "DELETE"
        try applyDefaultHeaders(request: &request)
        let response = try await data(forRequest: request, session: session)
        return try process(httpResponse: response)
    }
    
    public func get(route: AVServicesRoute, queryItems: [URLQueryItem]? = nil) async throws -> Data {
        let url = self.url.appendingPathComponent(route.route)
        guard var urlComponents = URLComponents(string: url.absoluteString) else {
            throw NetworkingError.badURL
        }
        urlComponents.queryItems = (queryItems ?? []) + (route.queryParams ?? [])
        guard let finalURL = urlComponents.url else {
            throw NetworkingError.badURL
        }
        var request: URLRequest = URLRequest(url: finalURL)
        try applyDefaultHeaders(request: &request)
        let response = try await data(forRequest: request, session: session)
        return try process(httpResponse: response)
    }
    
}



enum AVServicesRoute {
    case health
    case presignedGET
    
    
    var route: String {
        switch self {
        default:
            return "/\(String(describing: self))"
        }
    }
    
    var queryParams: [URLQueryItem]? {
        switch self {
        default:
            return nil
        }
    }

}
