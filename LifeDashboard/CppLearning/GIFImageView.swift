import SwiftUI
import UIKit
import ImageIO

struct GIFImageView: UIViewRepresentable {
    let filename: String
    var subdirectory: String = "CourseContent"

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        guard let url = AppStore.resourceURL(filename, subdirectory: subdirectory),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            imageView.image = UIImage(systemName: "photo")
            return imageView
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: Double = 0

        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }

            var delay = 0.1
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
               let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                if let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0 {
                    delay = unclamped
                } else if let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? Double, clamped > 0 {
                    delay = clamped
                }
            }
            delay = max(delay, 0.02)
            totalDuration += delay
            images.append(UIImage(cgImage: cgImage))
        }

        if images.isEmpty {
            imageView.image = UIImage(systemName: "photo")
        } else {
            imageView.animationImages = images
            imageView.animationDuration = max(totalDuration, 0.1)
            imageView.animationRepeatCount = 0
            imageView.startAnimating()
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}
