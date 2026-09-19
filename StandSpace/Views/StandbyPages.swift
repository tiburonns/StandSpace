import Combine
import ImageIO
import MediaPlayer
import PhotosUI
import SwiftUI
import UIKit

struct StandbyPhotoPage: View {
    let controlsVisible: Bool

    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?

    private var language: StandSpaceAppLanguage { .current }
    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }

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
                    Text(t("Photos", "Fotos"))
                        .font(.title2.bold())
                    Text(t("Choose a photo to use as a StandBy page.", "Elige una fotografía para usarla como página de StandBy."))
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
                                ? t("Choose Photo", "Elegir foto")
                                : t("Change Photo", "Cambiar foto"),
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
                      let normalized = normalizedJPEGData(from: data) else {
                    return
                }

                await MainActor.run {
                    image = normalized.image
                    try? normalized.data.write(
                        to: photoURL,
                        options: .atomic
                    )
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
        from data: Data
    ) -> (image: UIImage, data: Data)? {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            nil
        ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2200,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            return nil
        }

        let image = UIImage(cgImage: cgImage)
        guard let jpeg = image.jpegData(
            compressionQuality: 0.86
        ) else {
            return nil
        }

        return (image, jpeg)
    }
}

struct StandbyMusicPage: View {
    let controlsVisible: Bool

    @State private var authorization =
        MPMediaLibrary.authorizationStatus()
    @State private var nowPlayingTitle: String?
    @State private var nowPlayingArtist: String?
    @State private var hasNowPlayingItem = false
    @State private var artwork: UIImage?
    @State private var isPlaying = false

    private var language: StandSpaceAppLanguage { .current }
    private func t(_ english: String, _ spanish: String) -> String {
        language.text(english: english, spanish: spanish)
    }

    private var displayTitle: String {
        nowPlayingTitle ?? t("Music", "Música")
    }

    private var displayArtist: String {
        guard hasNowPlayingItem else {
            return t("Nothing Playing", "Nada reproduciéndose")
        }
        return nowPlayingArtist ?? t("Unknown Artist", "Artista desconocido")
    }

    private let player =
        MPMusicPlayerController.systemMusicPlayer

    private let refreshTimer = Timer
        .publish(
            every: 10,
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
                player.beginGeneratingPlaybackNotifications()
                refreshNowPlaying()
            }
        }
        .onDisappear {
            player.endGeneratingPlaybackNotifications()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .MPMusicPlayerControllerNowPlayingItemDidChange,
                object: player
            )
        ) { _ in
            guard authorization == .authorized else { return }
            refreshNowPlaying()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .MPMusicPlayerControllerPlaybackStateDidChange,
                object: player
            )
        ) { _ in
            guard authorization == .authorized else { return }
            refreshNowPlaying()
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
                Text(displayTitle)
                    .font(.title.bold())
                    .lineLimit(2)

                Text(displayArtist)
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

            Text(t("Music", "Música"))
                .font(.title2.bold())

            Text(t("Allow access to your library to show the current Apple Music song and use basic controls.", "Permite acceso a tu biblioteca para mostrar la canción actual de Apple Music y usar controles básicos."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 430)

            Button(t("Allow Access", "Permitir acceso")) {
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
                    player.beginGeneratingPlaybackNotifications()
                    refreshNowPlaying()
                }
            }
        }
    }

    private func refreshNowPlaying() {
        let item = player.nowPlayingItem

        hasNowPlayingItem = item != nil
        nowPlayingTitle = item?.title
        nowPlayingArtist = item?.artist

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
