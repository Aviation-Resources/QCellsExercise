//
//  FileDownloadState.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import Foundation

enum FileDownloadState {
    case neverStarted
    case requestingSignedURL
    case loading
    case error(Error)
    case finished(Data?)
    var isDownloaded: Bool {
        switch self {
        case .finished:
            return true
        default:
            return false
        }
    }
}
