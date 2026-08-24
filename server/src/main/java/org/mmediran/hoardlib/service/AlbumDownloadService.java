package org.mmediran.hoardlib.service;

import org.mmediran.hoardlib.domain.Album;
import org.mmediran.hoardlib.domain.Track;
import org.mmediran.hoardlib.repository.AlbumRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class AlbumDownloadService {

    private static final Logger log = LoggerFactory.getLogger(AlbumDownloadService.class);

    private final AlbumRepository albumRepository;

    public AlbumDownloadService(AlbumRepository albumRepository) {
        this.albumRepository = albumRepository;
    }

    @Transactional(readOnly = true)
    public ResponseEntity<StreamingResponseBody> downloadAlbumZip(Long albumId) {
        Optional<Album> albumOpt = albumRepository.findByIdWithArtistAndTracks(albumId);
        if (albumOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Album album = albumOpt.get();
        String artistName = album.getArtist() != null ? album.getArtist().getName() : "Unknown Artist";
        String zipFilename = artistName + " - " + album.getTitle() + ".zip";

        StreamingResponseBody responseBody = outputStream -> {
            try (ZipOutputStream zipOut = new ZipOutputStream(outputStream)) {
                // Add tracks
                if (album.getTracks() != null) {
                    for (Track track : album.getTracks()) {
                        File file = new File(track.getFilePath());
                        if (file.exists() && file.isFile()) {
                            ZipEntry zipEntry = new ZipEntry(file.getName());
                            zipOut.putNextEntry(zipEntry);
                            try (InputStream in = new FileInputStream(file)) {
                                in.transferTo(zipOut);
                            }
                            zipOut.closeEntry();
                        } else {
                            log.warn("Skipping missing track file during zip download: {}", track.getFilePath());
                        }
                    }
                }

                // Add cover.jpg if present
                if (album.getCoverPath() != null) {
                    File coverFile = new File(album.getCoverPath());
                    if (coverFile.exists() && coverFile.isFile()) {
                        ZipEntry coverEntry = new ZipEntry(coverFile.getName());
                        zipOut.putNextEntry(coverEntry);
                        try (InputStream in = new FileInputStream(coverFile)) {
                            in.transferTo(zipOut);
                        }
                        zipOut.closeEntry();
                    }
                }

                zipOut.finish();
            } catch (Exception e) {
                log.error("Error streaming album zip for albumId: {}", albumId, e);
                throw e;
            }
        };

        ContentDisposition contentDisposition = ContentDisposition.attachment()
                .filename(zipFilename, StandardCharsets.UTF_8)
                .build();

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition.toString())
                .contentType(MediaType.parseMediaType("application/zip"))
                .body(responseBody);
    }
}
