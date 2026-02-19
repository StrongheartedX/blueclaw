import UIKit

enum ImageCompressor {
    static func compress(_ image: UIImage, maxDimension: CGFloat = 800, quality: CGFloat = 0.5) -> (Data, String) {
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        let data = resized.jpegData(compressionQuality: quality) ?? Data()
        return (data, "image/jpeg")
    }
}
