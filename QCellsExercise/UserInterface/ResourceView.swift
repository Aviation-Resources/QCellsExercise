//
//  ResourceView.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation
import SwiftUI
import SDWebImage
import PDFKit
import ResourcesGraphQL

/// Insert some documentation here
struct ResourceView: View {
    let services: ServicesNetworking
    //MARK: State and Binding objects
    //@StateObject var imageNetworkingController: ImageNetworkingController = ImageNetworkingController()
    @State private var viewModel: ResourceViewModel = ResourceViewModel(pdfDocument: nil)
    @State var imageLoadingState: ImageLoadingState = .neverStarted
    //MARK: Other properties
    let resource: Resource
    let onOpenPDF: (PDFKitView, String) -> Void
    
    
    //MARK: View Body
    var body: some View {
        ZStack {
            ImageLoadingView(imageLoadingState: $imageLoadingState)
            downloadStateOverlay
        }.onTapGesture {
            tapped()
        }.task {
            await loadThumbnail()
            await checkDownloadState()
        }

    }
    
    @ViewBuilder
    private var downloadStateOverlay: some View {
        switch viewModel.fileDownloadState {
        case .neverStarted:
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .padding(18)
                .background(.blue.opacity(0.78), in: Circle())
        case .requestingSignedURL, .loading:
            ProgressView()
                .controlSize(.large)
                .padding(20)
                .background(.regularMaterial, in: Circle())
        case .error:
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .padding(18)
                .background(.red.opacity(0.78), in: Circle())
        case .finished:
            Image(systemName: "hand.tap")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .padding(18)
                .background(.blue.opacity(0.78), in: Circle())
        }
    }
    
    //MARK: Init if needed
    init(services: ServicesNetworking, resource: Resource, onOpenPDF: @escaping (PDFKitView, String) -> Void) {
        self.services = services
        self.resource = resource
        self.onOpenPDF = onOpenPDF
    }
    
    //MARK: Functions
    
    func tapped() {
        switch viewModel.fileDownloadState {
        case .finished(let p_data):
            if let pdfData = p_data  {
                guard let pdfDocument = PDFDocument(data: pdfData) else {
                    return
                }
                viewModel.pdfDocument = pdfDocument
            }else {
                let cachManager = SDImageCache(namespace: "resource-images")
                guard let fileData = cachManager.diskImageData(forKey: resource.s3_key) else {
                    return
                }
                guard let pdfDocument = PDFDocument(data: fileData) else {
                    return
                }
                viewModel.pdfDocument = pdfDocument
            }
            onOpenPDF(viewModel.pdfKitView, resource.documentNumber)
        default:
            Task { await downloadFile() }
        }
    }
    
    func loadThumbnail() async {
        do {
            let cachManager = SDImageCache(namespace: "resource-images")
            
            let key = resource.thumbnail_s3_key
            //print(key)
            let onDisk = await cachManager.diskImageExists(withKey: key)
            switch onDisk {
            case true:
                guard let imageData = cachManager.diskImageData(forKey: key) else {
                    throw NetworkingError.noData
                }
                let swiftuimage: Image = try getPlatformSpecificUIImage(imageData: imageData)
                imageLoadingState = .finished(swiftuimage)
            case false:
                imageLoadingState = .requestingSignedURL
                let thumbnailKey = key
                let postBody = PresignedGETPOSTBody(key: thumbnailKey, bucket: services.env.s3Bucket)
                let resultData = try await services.post(encodableObject: postBody, route: .presignedGET)
                let response = try JSONDecoder().decode(PresignedGETResponse.self, from: resultData)
                imageLoadingState = .loading
                guard let url = URL(string: response.url) else {
                    throw NetworkingError.badURL
                }
                let imageDateRequest = URLRequest(url: url)
                let imageDataResponse = try await services.data(forRequest: imageDateRequest, session: URLSession.shared)
                let imageData = imageDataResponse.0
                cachManager.storeImageData(toDisk: imageData, forKey: thumbnailKey)
                let swiftuimage: Image = try getPlatformSpecificUIImage(imageData: imageData)
                imageLoadingState = .finished(swiftuimage)
            }
        }catch {
            imageLoadingState = .error(error)
        }
    }
    
    func getPlatformSpecificUIImage(imageData: Data) throws -> Image {
        var swiftuimage: Image!
        
        #if os(macOS)
        guard let nsmage = NSImage(data: imageData) else {
            throw NetworkingError.noData
        }
        swiftuimage = Image(nsImage: nsmage)
        #elseif os(iOS)
        guard let uiimage = UIImage(data: imageData) else {
            throw NetworkingError.noData
        }
        swiftuimage = Image(uiImage: uiimage)
        #endif
        return swiftuimage
    }
    
    func downloadFile() async {
        do {
            let cachManager = SDImageCache(namespace: "resource-images")
            let onDisk = await cachManager.diskImageExists(withKey: resource.s3_key)
            switch onDisk {
            case true:
                guard let fileData = cachManager.diskImageData(forKey: resource.s3_key) else {
                    throw NetworkingError.noData
                }
                viewModel.fileDownloadState = .finished(fileData)
            case false:
                viewModel.fileDownloadState = .requestingSignedURL
                let bucket = services.env.s3Bucket
                let key = resource.s3_key
                let postBody = PresignedGETPOSTBody(key: key, bucket: bucket)
                let resultData = try await services.post(encodableObject: postBody, route: .presignedGET)
                let response = try JSONDecoder().decode(PresignedGETResponse.self, from: resultData)
                viewModel.fileDownloadState = .loading
                guard let url = URL(string: response.url) else {
                    throw NetworkingError.badURL
                }
                let fileDateRequest = URLRequest(url: url)
                let fileDataResponse = try await services.data(forRequest: fileDateRequest, session: URLSession.shared)
                let fileData = fileDataResponse.0
                cachManager.storeImageData(toDisk: fileData, forKey: resource.s3_key)
                viewModel.fileDownloadState = .finished(fileData)
            }
        }catch {
            if let error = error as? NetworkingError {
                print(error.description)
            }else {
                print(error.localizedDescription)
            }
            viewModel.fileDownloadState = .error(error)
        }
    }

    
    
    func checkDownloadState() async {
        let cachManager = SDImageCache(namespace: "resource-images")
        let onDisk = await cachManager.diskImageExists(withKey: resource.s3_key)
        switch onDisk {
        case true:
            viewModel.fileDownloadState = .finished(nil)
        case false:
            viewModel.fileDownloadState = .neverStarted
        }
    }
}

@Observable
fileprivate class ResourceViewModel {
    
    var fileDownloadState: FileDownloadState = .neverStarted {
        didSet {
            isDownloaded = fileDownloadState.isDownloaded
        }
    }
    var isDownloaded: Bool = false
    var destination: PDFDestination? {
        didSet {
            showOutlinePopover = false

            guard let destination else {
                return
            }

            pdfKitView.goTo(destination: destination)
        }
    }
    var pdfDocument: PDFDocument? {
        didSet {
            pdfKitView.updateDocument(document: pdfDocument)
        }
    }
    var showPDF: Bool = false
    var showOutlinePopover: Bool = false
    
    let pdfKitView: PDFKitView

    @MainActor
    init(pdfDocument: PDFDocument?) {
        pdfKitView = PDFKitView(showing: pdfDocument)
        self.pdfDocument = pdfDocument
    }
    
}
