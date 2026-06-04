//
//  Environment.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation
import Combine

enum EnvironmentType: String {
    case PROD
}

protocol NetworkingEnvironment: Sendable {
    ///The type of the environment
    var type: EnvironmentType { get }
    /// The URL string of the GraphQL API
    var graphQLURLString: String { get }
    /// The URL of the REST API (Services)
    var apiURLString: String { get }
    
    var s3Bucket: String { get }
    
    var graphQLURL: URL? { get }
    
    var apiURL: URL? { get }
}

extension NetworkingEnvironment {
    var graphQLURL: URL? {
        return URL(string: graphQLURLString)
    }
    
    var apiURL: URL? {
        return URL(string: apiURLString)
    }
}

struct Production: NetworkingEnvironment {
    var type: EnvironmentType = .PROD
    
    var graphQLURLString: String = "https://graphql.aviationresources.io/v1/graphql"
    
    var apiURLString: String = "https://api.aviationresources.io"
    
    var s3Bucket: String = "ar-resources-production"
    
}
