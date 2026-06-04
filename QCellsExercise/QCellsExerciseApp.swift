//
//  QCellsExerciseApp.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import SwiftUI

@main
struct QCellsExerciseApp: App {
    
    let setupState: SetupState
    
    enum SetupState {
        case setup(graphQLNetworking: GraphQLNetworking, services: ServicesNetworking)
        case error(Error)
    }
    
    var body: some Scene {
        WindowGroup {
            switch setupState {
            case .setup(graphQLNetworking: let graphQL, services: let services):
                NavigationStack {
                    ResourcesListView(graphQLNetworking: graphQL, servicesNetworking: services).navigationTitle(Text("Resources"))
                }
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
    }
    
    init() {
        do {
            let environment = Production()
            let networking = try GraphQLNetworking(environment: environment)
            let servicesNetworking = try ServicesNetworking(env: environment)
            self.setupState = .setup(graphQLNetworking: networking, services: servicesNetworking)
        }catch {
            self.setupState = .error(error)
        }
    }
    
}
