//
//  NetworkingError.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation
import Apollo
import ResourcesGraphQL

enum NetworkingError: Error, CustomStringConvertible {
    
    case noUser
    case badURL
    case graphQL(errors: [GraphQLError])
    case noData
    case badResponse
    case badStatusCode(code: Int, data: Data)
    
    
    var description: String {
        switch self {
        case .noUser:
            return "The user could not be found."
        case .badURL:
            return "The URL could not be found."
        case .graphQL(let errors):
            let errorString = errors.first?.localizedDescription ?? "Unknown GraphQL Error"
            return errorString
        case .noData:
            return "No data returned from the server."
        case .badResponse:
            return "Response error"
        case .badStatusCode(code: let code):
            return "Bad status code: \(code)"
        }
    }
}
