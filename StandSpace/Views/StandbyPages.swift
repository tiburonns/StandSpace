import Combine
import MediaPlayer
import PhotosUI
import SwiftUI
import UIKit

struct StandbyPhotoPage: View {
    let controlsVisible: Bool

    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.10),
                                Color.black.opacity(0.28)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 52))
                    Text("Fotos")
                        .font(.title2.bold())
                    Text("Elige una fotografía para usarla como página de StandBy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                }
            }

            if controlsVisible || image == nil {
                VStack {
                    Spacer()

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        Label(
                            image == nil
                                ? "Elegir foto"
                                : "Cambiar foto",
                            systemImage: "photo.badge.plus"
                        )
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            .ultraThinMaterial,
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 48)
                }
            }
        }
        .task {
            loadSavedPhoto()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem = newItem else { return }

            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let loaded = UIImage(data: data) else {
                    return
                }

                let normalized = normalizedJPEGData(from: loaded)

                await MainActor.run {
                    image = loaded
                    if let normalized = normalized {
                        try? normalized.write(
                            to: photoURL,
                            options: .atomic
                        )
                    }
                }
            }
        }
    }

    private var photoURL: URL {
        let directory = FileManager.default
            .urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            .appendingPathComponent(
                "StandSpace",
                isDirectory: true
            )

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory.appendingPathComponent(
            "standby-photo.jpg"
        )
    }

    private func loadSavedPhoto() {
        guard let data = try? Data(contentsOf: photoURL),
              let saved = UIImage(data: data) else {
            return
        }

        image = saved
    }

    private func normalizedJPEGData(
        from image: UIImage
    ) -> Data? {
        let maxDimension: CGFloat = 2200
        let largest = max(
            image.size.width,
            image.size.height
        )

        guard largest > 0 else {
            return nil
        }

        let scale = min(1, maxDimension / largest)
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(
            size: targetSize
        )

        let resized = renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: targetSize
                )
            )
        }

        return resized.jpegData(
            compressionQuality: 0.86
        )
    }
}

struct StandbyMusicPage: View {
    let controlsVisible: Bool

    @State private var authorization =
        MPMediaLibrary.authorizationStatus()
    @State private var title = "Música"
    @State private var artist = "Nada reproduciéndose"
    @State private var artwork: UIImage?
    @State private var isPlaying = false

    private let player =
        MPMusicPlayerController.systemMusicPlayer

    private let refreshTimer = Timer
        .publish(
            every: 1,
            on: .main,
            in: .common
        )
        .autoconnect()

    var body: some View {
        ZStack {
            if let artwork = artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 28)
                    .scaleEffect(1.12)
                    .opacity(0.38)
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if authorization == .authorized {
                authorizedContent
            } else {
                permissionContent
            }
        }
        .onAppear {
            if authorization == .authorized {
                refreshNowPlaying()
            }
        }
        .onReceive(refreshTimer) { _ in
            guard authorization == .authorized else {
                return
            }

            refreshNowPlaying()
        }
    }

    private var authorizedContent: some View {
        HStack(spacing: 30) {
            Group {
                if let artwork = artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.white.opacity(0.08)
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 190, height: 190)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
            .shadow(
                color: .black.opacity(0.30),
                radius: 24,
                y: 12
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title.bold())
                    .lineLimit(2)

                Text(artist)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if controlsVisible {
                    HStack(spacing: 22) {
                        Button {
                            player.skipToPreviousItem()
                        } label: {
                            Image(systemName: "backward.fill")
                        }

                        Button {
                            if isPlaying {
                                player.pause()
                            } else {
                                player.play()
                            }

                            refreshNowPlaying()
                        } label: {
                            Image(
                                systemName:
                                    isPlaying
                                    ? "pause.fill"
                                    : "play.fill"
                            )
                            .font(.title2)
                        }

                        Button {
                            player.skipToNextItem()
                        } label: {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .font(.title3)
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 24)
    }

    private var permissionContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note")
                .font(.system(size: 50))

            Text("Música")
                .font(.title2.bold())

            Text("Permite acceso a tu biblioteca para mostrar la canción actual de Apple Music y usar controles básicos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 430)

            Button("Permitir acceso") {
                requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func requestAuthorization() {
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                authorization = status

                if status == .authorized {
                    refreshNowPlaying()
                }
            }
        }
    }

    private func refreshNowPlaying() {
        let item = player.nowPlayingItem

        title =
            item?.title
            ?? "Música"

        artist =
            item?.artist
            ?? (
                item == nil
                ? "Nada reproduciéndose"
                : "Artista desconocido"
            )

        artwork = item?.artwork?.image(
            at: CGSize(
                width: 700,
                height: 700
            )
        )

        isPlaying =
            player.playbackState == .playing
    }
}
