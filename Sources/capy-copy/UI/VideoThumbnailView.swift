import SwiftUI
import QuickLookThumbnailing

struct VideoThumbnailView: View {
    let url: URL
    let maxHeight: CGFloat
    let cornerRadius: CGFloat

    @State private var thumbnailImage: NSImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(maxHeight: maxHeight)
            } else {
                HStack {
                    Image(systemName: "film")
                    Text("Preview unavailable")
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxHeight: maxHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            generateThumbnail()
        }
        .onChange(of: url) { _ in
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        isLoading = true
        let size = CGSize(width: 600, height: 600)
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: NSScreen.main?.backingScaleFactor ?? 1,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
            DispatchQueue.main.async {
                isLoading = false
                if let representation = representation {
                    thumbnailImage = representation.nsImage
                } else if let error = error {
                    print("Thumbnail generation error: \(error)")
                }
            }
        }
    }
}
