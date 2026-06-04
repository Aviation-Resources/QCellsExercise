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


enum ImageLoadingState {
    case neverStarted
    case requestingSignedURL
    case loading
    case error(Error)
    case finished(Image)
}

@Observable
class PDFViewModel {
    
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

/// Insert some documentation here
struct ResourceView: View {
    let services: ServicesNetworking
    //MARK: State and Binding objects
    //@StateObject var imageNetworkingController: ImageNetworkingController = ImageNetworkingController()
    @State private var viewModel: PDFViewModel = PDFViewModel(pdfDocument: nil)
    @State var imageLoadingState: ImageLoadingState = .neverStarted
    @State var showPDF: Bool = false
    //MARK: Other properties
    let resource: Resource
    
    
    //MARK: View Body
    var body: some View {
        ZStack {
            ImageLoadingView(imageLoadingState: $imageLoadingState)
            
            switch viewModel.isDownloaded {
            case true:
                EmptyView()
            case false:
                Color.blue.opacity(0.2)
            }
            
            VStack(alignment: .center, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    //ImageOverlayText(text: resource.documentNumber, font: .caption, isDownloaded: $viewModel.isDownloaded)
                    Spacer()
                   // FileLoadingView(fileDownloadState: $viewModel.fileDownloadState)
                }
                Spacer()
            }.padding([.leading, .top, .trailing], 8)
            
            VStack(spacing: 0) {
                Spacer()
//                ImageOverlayText(text: resource.documentName, font: .body, isDownloaded: $viewModel.isDownloaded).frame(maxHeight: 90).padding([.leading, .bottom, .trailing], 8)
            }
        }.onTapGesture {
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
                showPDF = true
            default:
                downloadFile()
            }
        }.onAppear {
            loadThumbnail()
            checkDownloadState()
        }.navigationDestination(isPresented: $showPDF) {
            viewModel.pdfKitView.navigationTitle(resource.documentNumber)
        }

    }
    
    //MARK: Init if needed
    init(services: ServicesNetworking, resource: Resource) {
        self.services = services
        self.resource = resource
    }
    
    //MARK: Functions
    
    func loadThumbnail() {
        Task {
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
    
    func downloadFile() {
        Task {
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
    }

    
    
    func checkDownloadState() {
        Task {
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
}
