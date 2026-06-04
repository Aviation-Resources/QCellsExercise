//
//  ImageLoadingView.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation
import SwiftUI

/// Insert some documentation here
struct ImageLoadingView: View {
    //MARK: Environment and State objects
    
    //MARK: State and Binding objects
    @Binding var imageLoadingState: ImageLoadingState
    //MARK: Other properties
    let minHeight: CGFloat = 250
    //MARK: View Body
    var body: some View {
        ZStack {
            switch imageLoadingState {
            case .neverStarted:
                Image(systemName: "photo").font(.system(size: 25)).foregroundColor(Color.blue)
            case .loading, .requestingSignedURL:
                ProgressView()
            case .error(let error):
                VStack {
                    Image(systemName: "exclamationmark.icloud").font(.system(size: 25)).foregroundColor(Color.blue)
                    switch error {
                    case let localized as LocalizedError:
                        Text(localized.localizedDescription).font(.footnote).foregroundColor(Color.gray)
                    case let custom as CustomStringConvertible:
                        Text(custom.description).font(.footnote).foregroundColor(Color.gray)
                    default:
                        Text(error.localizedDescription).font(.footnote).foregroundColor(Color.gray)
                    }
                }

            case .finished(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            }
        }.frame(minHeight: minHeight)
    }
    
    //MARK: Init if needed
    init(imageLoadingState: Binding<ImageLoadingState>) {
        self._imageLoadingState = imageLoadingState
    }
    
    //MARK: Functions

    
}

