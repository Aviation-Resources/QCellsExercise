//
//  GraphQLNetworking.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation
import Apollo
import ResourcesGraphQL

class GraphQLNetworking: Sendable {

    let apolloClient: ApolloClient
    
 
    
    init(environment: NetworkingEnvironment) throws {
        guard let graphQLURL: URL = environment.graphQLURL else {
            throw NetworkingError.badURL
        }

        let interceptorProvider: NetworkInterceptorProvider = NetworkInterceptorProvider()
        let networkTransport: RequestChainNetworkTransport = RequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: graphQLURL)
        apolloClient = ApolloClient(networkTransport: networkTransport, store: interceptorProvider.store)
    }
    
    
    func fetch<Q: GraphQLQuery>(query: Q, cachePolicy: CachePolicy = .fetchIgnoringCacheCompletely) async throws -> Q.Data {
        return try await withCheckedThrowingContinuation({ continuation in
            apolloClient.fetch(query: query, cachePolicy: cachePolicy, contextIdentifier: nil) { results in
                switch results {
                case .failure(let error):
                    return continuation.resume(throwing: error)
                case .success(let graphQLResults):
                    guard let errors = graphQLResults.errors else {
                        guard let returnData = graphQLResults.data else {
                            continuation.resume(throwing: NetworkingError.noData)
                            return
                        }
                        
                        continuation.resume(returning: returnData)
                        return
                    }
                    continuation.resume(throwing: NetworkingError.graphQL(errors: errors))
                }
            }
        })
    }
}

struct NetworkInterceptorProvider: InterceptorProvider {
    
    // These properties will remain the same throughout the life of the `InterceptorProvider`, even though they
    // will be handed to different interceptors.
    let store: ApolloStore
    let client: URLSessionClient
    
    init() {
        let cache: InMemoryNormalizedCache = InMemoryNormalizedCache()
        let store: ApolloStore = ApolloStore(cache: cache)
        let client: URLSessionClient = URLSessionClient()
        self.store = store
        self.client = client
    }
    
    func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        return [
            MaxRetryInterceptor(),
            CacheReadInterceptor(store: self.store),
            NetworkFetchInterceptor(client: self.client),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
            AutomaticPersistedQueryInterceptor(),
            CacheWriteInterceptor(store: self.store)
        ]
    }
}
