import SwiftUI
import PDFKit

struct CalcPDFViewer: View {
    let fileName: String
    let title: String
    var subdirectory: String = "CourseContent"

    var body: some View {
        CalcPDFKitRepresentedView(url: CalcAppStore.resourceURL(fileName, subdirectory: subdirectory))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct CalcPDFKitRepresentedView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        if let url {
            pdfView.document = PDFDocument(url: url)
        }
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}
}
