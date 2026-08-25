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

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.zip.Deflater;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class AlbumDownloadService {

    private static final Logger log = LoggerFactory.getLogger(AlbumDownloadService.class);
    private static final int BUFFER_SIZE = 64 * 1024; // 64KB buffer

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
            try (BufferedOutputStream bufferedOut = new BufferedOutputStream(outputStream, BUFFER_SIZE);
                 ZipOutputStream zipOut = new ZipOutputStream(bufferedOut)) {

                // Audio files are already compressed (MP3, M4A, FLAC, OPUS, etc.).
                // Setting NO_COMPRESSION drastically speeds up streaming and avoids CPU/timeout bottlenecks.
                zipOut.setLevel(Deflater.NO_COMPRESSION);

                byte[] buffer = new byte[BUFFER_SIZE];

                // Add tracks
                if (album.getTracks() != null) {
                    for (Track track : album.getTracks()) {
                        File file = new File(track.getFilePath());
                        if (file.exists() && file.isFile()) {
                            ZipEntry zipEntry = new ZipEntry(file.getName());
                            zipOut.putNextEntry(zipEntry);
                            try (InputStream in = new FileInputStream(file)) {
                                int bytesRead;
                                while ((bytesRead = in.read(buffer)) != -1) {
                                    zipOut.write(buffer, 0, bytesRead);
                                }
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
                            int bytesRead;
                            while ((bytesRead = in.read(buffer)) != -1) {
                                zipOut.write(buffer, 0, bytesRead);
                            }
                        }
                        zipOut.closeEntry();
                    }
                }

                zipOut.finish();
                bufferedOut.flush();
            } catch (IOException e) {
                if (isClientAbortException(e)) {
                    log.info("Client cancelled download for albumId: {} ({})", albumId, e.getMessage());
                } else {
                    log.error("IO error streaming album zip for albumId: {}", albumId, e);
                    throw e;
                }
            } catch (Exception e) {
                log.error("Unexpected error streaming album zip for albumId: {}", albumId, e);
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

    private boolean isClientAbortException(Throwable t) {
        while (t != null) {
            String className = t.getClass().getName();
            String msg = t.getMessage();
            if (className.contains("ClientAbortException") ||
                (msg != null && (msg.contains("Broken pipe") || msg.contains("Connection reset by peer")))) {
                return true;
            }
            t = t.getCause();
        }
        return false;
    }
}
