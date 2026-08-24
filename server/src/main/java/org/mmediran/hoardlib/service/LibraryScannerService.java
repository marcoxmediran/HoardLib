package org.mmediran.hoardlib.service;

import org.mmediran.hoardlib.domain.Album;
import org.mmediran.hoardlib.domain.Artist;
import org.mmediran.hoardlib.domain.Track;
import org.mmediran.hoardlib.dto.ScanSummaryDto;
import org.mmediran.hoardlib.repository.AlbumRepository;
import org.mmediran.hoardlib.repository.ArtistRepository;
import org.mmediran.hoardlib.repository.TrackRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

@Service
public class LibraryScannerService {

    private static final Logger log = LoggerFactory.getLogger(LibraryScannerService.class);

    // Matches "<Album Title> (<YearOrDate>)", e.g. "The Original Soundtrack (2006)" or "Ponpon_Live (20250409)"
    private static final Pattern ALBUM_DIR_WITH_YEAR_PATTERN = Pattern.compile("^(.+)\\s+\\((\\d{4,8})\\)$");

    // Matches "<TrackNumber>. <Title>.<ext>", e.g. "01. Une Nuit a Paris.mp3"
    private static final Pattern TRACK_FILE_PATTERN = Pattern.compile(
            "^(\\d+)\\.\\s*(.+)\\.(mp3|flac|m4a|aac|ogg|opus|wav)$",
            Pattern.CASE_INSENSITIVE
    );

    private static final String COVER_FILENAME = "cover.jpg";

    private final String libraryPath;
    private final ArtistRepository artistRepository;
    private final AlbumRepository albumRepository;
    private final TrackRepository trackRepository;

    public LibraryScannerService(
            @Value("${music.library.path}") String libraryPath,
            ArtistRepository artistRepository,
            AlbumRepository albumRepository,
            TrackRepository trackRepository
    ) {
        this.libraryPath = libraryPath;
        this.artistRepository = artistRepository;
        this.albumRepository = albumRepository;
        this.trackRepository = trackRepository;
    }

    @Transactional
    public synchronized ScanSummaryDto scanLibrary() {
        long startTime = System.currentTimeMillis();
        log.info("Starting music library scan at path: {}", libraryPath);

        Path rootPath = Path.of(libraryPath);
        if (!Files.exists(rootPath) || !Files.isDirectory(rootPath)) {
            log.warn("Music library path does not exist or is not a directory: {}", libraryPath);
            return new ScanSummaryDto(0, 0, 0, System.currentTimeMillis() - startTime, "Library path not found");
        }

        int scannedArtists = 0;
        int scannedAlbums = 0;
        int scannedTracks = 0;

        Set<Long> visitedArtistIds = new HashSet<>();
        Set<Long> visitedAlbumIds = new HashSet<>();
        Set<Long> visitedTrackIds = new HashSet<>();

        try (Stream<Path> artistPaths = Files.list(rootPath)) {
            List<Path> artistDirList = artistPaths
                    .filter(Files::isDirectory)
                    .filter(p -> !p.getFileName().toString().startsWith("."))
                    .sorted()
                    .toList();

            for (Path artistDir : artistDirList) {
                String artistName = artistDir.getFileName().toString().trim();
                if (artistName.isEmpty()) {
                    continue;
                }

                Artist artist = artistRepository.findByName(artistName)
                        .orElseGet(() -> artistRepository.save(new Artist(artistName)));

                visitedArtistIds.add(artist.getId());
                scannedArtists++;

                try (Stream<Path> albumPaths = Files.list(artistDir)) {
                    List<Path> albumDirList = albumPaths
                            .filter(Files::isDirectory)
                            .filter(p -> !p.getFileName().toString().startsWith("."))
                            .sorted()
                            .toList();

                    for (Path albumDir : albumDirList) {
                        String albumDirName = albumDir.getFileName().toString().trim();
                        final String albumTitle;
                        final Integer albumYear;

                        Matcher albumMatcher = ALBUM_DIR_WITH_YEAR_PATTERN.matcher(albumDirName);
                        if (albumMatcher.matches()) {
                            albumTitle = albumMatcher.group(1).trim();
                            String yearOrDate = albumMatcher.group(2).trim();
                            albumYear = yearOrDate.length() >= 4 ? Integer.parseInt(yearOrDate.substring(0, 4)) : null;
                        } else {
                            albumTitle = albumDirName;
                            albumYear = null;
                        }

                        // Check for cover.jpg
                        Path coverFile = albumDir.resolve(COVER_FILENAME);
                        String coverPath = Files.isRegularFile(coverFile) ? coverFile.toAbsolutePath().toString() : null;

                        // Upsert Album preserving listened state
                        Album album = albumRepository.findByTitleAndArtistName(albumTitle, artistName)
                                .orElseGet(() -> new Album(albumTitle, albumYear, artist));

                        album.setYear(albumYear);
                        album.setCoverPath(coverPath);
                        album.setArtist(artist);
                        album = albumRepository.save(album);

                        visitedAlbumIds.add(album.getId());
                        scannedAlbums++;

                        // Scan tracks inside album directory
                        Map<String, Track> existingTracksByPath = new HashMap<>();
                        if (album.getTracks() != null) {
                            for (Track t : album.getTracks()) {
                                existingTracksByPath.put(t.getFilePath(), t);
                            }
                        }

                        Set<String> scannedFilePaths = new HashSet<>();

                        try (Stream<Path> trackPaths = Files.list(albumDir)) {
                            List<Path> trackFileList = trackPaths
                                    .filter(Files::isRegularFile)
                                    .sorted()
                                    .toList();

                            for (Path trackFile : trackFileList) {
                                String filename = trackFile.getFileName().toString();
                                Matcher trackMatcher = TRACK_FILE_PATTERN.matcher(filename);

                                if (!trackMatcher.matches()) {
                                    continue;
                                }

                                int trackNumber = Integer.parseInt(trackMatcher.group(1).trim());
                                String trackTitle = trackMatcher.group(2).trim();
                                String extension = trackMatcher.group(3).toLowerCase();
                                String absolutePath = trackFile.toAbsolutePath().toString();
                                long fileSize = Files.size(trackFile);
                                scannedFilePaths.add(absolutePath);

                                Track track = existingTracksByPath.get(absolutePath);
                                if (track == null) {
                                    track = new Track(trackTitle, trackNumber, absolutePath, fileSize, extension, album);
                                    album.addTrack(track);
                                } else {
                                    track.setTitle(trackTitle);
                                    track.setTrackNumber(trackNumber);
                                    track.setFileSizeBytes(fileSize);
                                    track.setExtension(extension);
                                    track.setAlbum(album);
                                }

                                track = trackRepository.save(track);
                                visitedTrackIds.add(track.getId());
                                scannedTracks++;
                            }
                        }

                        if (album.getTracks() != null) {
                            album.getTracks().removeIf(t -> !scannedFilePaths.contains(t.getFilePath()));
                        }
                        albumRepository.save(album);
                    }
                }
            }

            // Cleanup removed entities
            cleanupOrphanedEntities(visitedArtistIds, visitedAlbumIds, visitedTrackIds);

        } catch (IOException e) {
            log.error("Failed to scan music library", e);
            return new ScanSummaryDto(scannedArtists, scannedAlbums, scannedTracks, System.currentTimeMillis() - startTime, "Scan error: " + e.getMessage());
        }

        long duration = System.currentTimeMillis() - startTime;
        log.info("Library scan completed in {} ms: {} artists, {} albums, {} tracks",
                duration, scannedArtists, scannedAlbums, scannedTracks);

        return new ScanSummaryDto(scannedArtists, scannedAlbums, scannedTracks, duration, "SUCCESS");
    }

    private void cleanupOrphanedEntities(Set<Long> visitedArtistIds, Set<Long> visitedAlbumIds, Set<Long> visitedTrackIds) {
        List<Track> allTracks = trackRepository.findAll();
        for (Track track : allTracks) {
            if (!visitedTrackIds.contains(track.getId())) {
                trackRepository.delete(track);
            }
        }

        List<Album> allAlbums = albumRepository.findAll();
        for (Album album : allAlbums) {
            if (!visitedAlbumIds.contains(album.getId())) {
                albumRepository.delete(album);
            }
        }

        List<Artist> allArtists = artistRepository.findAll();
        for (Artist artist : allArtists) {
            if (!visitedArtistIds.contains(artist.getId())) {
                artistRepository.delete(artist);
            }
        }
    }
}
