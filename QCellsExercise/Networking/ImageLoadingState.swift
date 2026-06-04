//
//  ImageLoadingState.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//
import Foundation
import SwiftUI

enum ImageLoadingState {
    case neverStarted
    case requestingSignedURL
    case loading
    case error(Error)
    case finished(Image)
}
