//
//  PDFKitView.swift
//  QCellsExercise
//
//  Created by Jon Vogel on 6/3/26.
//

import SwiftUI
import PDFKit

#if os(iOS)
struct PDFKitView: UIViewRepresentable {
    
    let pdfView: PDFView = PDFView()
    
    init(showing pdfDoc: PDFDocument?) {
        pdfView.document = pdfDoc
    }
    
    //you could also have inits that take a URL or Data
    
    func makeUIView(context: Context) -> PDFView {
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        
    }
    
    func goTo(destination: PDFDestination) {
        pdfView.go(to: destination)
    }
    
    func updateDocument(document: PDFDocument?) {
        self.pdfView.document = document
    }
}
#elseif os(macOS)
struct PDFKitView: NSViewRepresentable {
    
    let pdfView: PDFView = PDFView()
    
    init(showing pdfDoc: PDFDocument?) {
        pdfView.document = pdfDoc
    }
    
    // You could also have inits that take a URL or Data
    
    func makeNSView(context: Context) -> PDFView {
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        
    }
    
    func goTo(destination: PDFDestination) {
        pdfView.go(to: destination)
    }
    
    func updateDocument(document: PDFDocument?) {
        self.pdfView.document = document
    }
}
#endif
