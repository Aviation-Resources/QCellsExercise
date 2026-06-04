//
//  ResourcesListView.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation
import SwiftUI
import ResourcesGraphQL

/*
 
 TODO:
 Show new file after upload
 Edit file name and number
 Preview page
 Index Status
 
 */

/// Insert some documentation here
struct ResourcesListView: View {
    //MARK: Environment and State objects
    let graphQLNetworking: GraphQLNetworking
    let servicesNetworking: ServicesNetworking
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.verticalSizeClass) private var verticalSizeClass: UserInterfaceSizeClass?


    @Bindable var model: ResourcesFilterModel = ResourcesFilterModel()
    
    let compactColumns: [GridItem] = [GridItem()]
    let regularColumns: [GridItem] = [GridItem(), GridItem(), GridItem(), GridItem()]
    
    //MARK: View Body
    var body: some View {
        ZStack {
            switch model.networkingState {
            case .neverCalled:
                Text("Never Called")
            case .networking:
                ProgressView()
            case .finished:
                ScrollView {
                    switch (horizontalSizeClass, verticalSizeClass) {
                    case(.regular, .regular):
                        LazyVGrid(columns: regularColumns) {
                            content
                        }
                    default:
                        LazyVGrid(columns: compactColumns) {
                            content
                        }
                    }
                }.searchable(text: $model.searchText)
            case .error(let error):
                Text(error.localizedDescription)
            }
        }.toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                sortMenu
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                sortMenu
            }
            #endif
        }.task {
            await model.loadSourceData(networkingController: graphQLNetworking)
        }
    }
    
    var content: some View {
        ForEach(model.filteredResources) { resource in
            ResourceView(services: self.servicesNetworking, resource: resource).padding()
        }
    }
    
    var sortMenu: some View {
        Menu {
            Button("Document Name") {
                model.sortOption = .documentName
            }
            
            Button("Document Number") {
                model.sortOption = .documentNumber
            }
        } label: {
            Label("Sort Resources", systemImage: "arrow.up.arrow.down")
        }
    }
    
    //MARK: Init if needed
    init(graphQLNetworking: GraphQLNetworking, servicesNetworking: ServicesNetworking) {
        self.graphQLNetworking = graphQLNetworking
        self.servicesNetworking = servicesNetworking
    }
    
    //MARK: Functions
    
}


enum ResourceSortOption {
    case documentName
    case documentNumber
}

@Observable
class ResourcesFilterModel {
    
    var networkingState: NetworkingState = NetworkingState.neverCalled
    var resources: [Resource] = [] {
        didSet {
            updateFilteredResources()
        }
    }
    var filteredResources: [Resource] = []
    var searchText: String = "" {
        didSet {
            updateFilteredResources()
        }
    }
    var sortOption: ResourceSortOption? {
        didSet {
            updateFilteredResources()
        }
    }
    
    enum NetworkingState {
        case neverCalled
        case networking
        case finished
        case error(Error)
    }
    
    init() {

    }
    
    func search(searchString: String) {
        searchText = searchString
    }
    
    private func updateFilteredResources() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [Resource]
        
        if query.isEmpty {
            filtered = resources
        } else {
            filtered = resources.filter {
                $0.documentName.localizedCaseInsensitiveContains(query) || $0.documentNumber.localizedCaseInsensitiveContains(query)
            }
        }
        
        switch sortOption {
        case .documentName:
            filteredResources = filtered.sorted {
                $0.documentName.localizedCaseInsensitiveCompare($1.documentName) == .orderedAscending
            }
        case .documentNumber:
            filteredResources = filtered.sorted {
                $0.documentNumber.localizedCaseInsensitiveCompare($1.documentNumber) == .orderedAscending
            }
        case nil:
            filteredResources = filtered
        }
    }
    
    
    @MainActor
    func loadSourceData(networkingController: GraphQLNetworking) async {
        do {
            networkingState = .networking
            let query = DocumentsQuery()
            resources = try await networkingController.fetch(query: query).resourceQuery.map { $0.fragments.resource }
            networkingState = .finished
        }catch {
            networkingState = .error(error)
        }
    }
    
    
    static func mock() -> ResourcesFilterModel {
        let model = ResourcesFilterModel()
        return model
    }
    
}

extension Resource: @retroactive Identifiable { }
