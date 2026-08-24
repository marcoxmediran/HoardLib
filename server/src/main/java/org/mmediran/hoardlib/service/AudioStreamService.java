package org.mmediran.hoardlib.service;

import org.mmediran.hoardlib.domain.Track;
import org.mmediran.hoardlib.repository.TrackRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.ResourceRegion;
import org.springframework.http.*;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Optional;

@Service
public class AudioStreamService {

    private static final Logger log = LoggerFactory.getLogger(AudioStreamService.class);
    private static final long CHUNK_SIZE = 1024 * 1024; // 1MB buffer chunk

    private final TrackRepository trackRepository;

    public AudioStreamService(TrackRepository trackRepository) {
        this.trackRepository = trackRepository;
    }

    public ResponseEntity<ResourceRegion> streamTrack(Long trackId, HttpHeaders headers) {
        Optional<Track> trackOpt = trackRepository.findById(trackId);
        if (trackOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Track track = trackOpt.get();
        File file = new File(track.getFilePath());
        if (!file.exists() || !file.isFile()) {
            log.warn("Track file not found on disk: {}", track.getFilePath());
            return ResponseEntity.notFound().build();
        }

        Resource resource = new FileSystemResource(file);
        MediaType mediaType = getMediaTypeForExtension(track.getExtension());
        long contentLength = file.length();

        List<HttpRange> ranges = headers.getRange();
        if (ranges == null || ranges.isEmpty()) {
            ResourceRegion region = new ResourceRegion(resource, 0, contentLength);
            return ResponseEntity.ok()
                    .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                    .contentType(mediaType)
                    .contentLength(contentLength)
                    .body(region);
        }

        HttpRange range = ranges.get(0);
        long start = range.getRangeStart(contentLength);
        long end = range.getRangeEnd(contentLength);
        long rangeLength = Math.min(CHUNK_SIZE, end - start + 1);

        ResourceRegion region = new ResourceRegion(resource, start, rangeLength);

        return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT)
                .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                .contentType(mediaType)
                .body(region);
    }

    public MediaType getMediaTypeForExtension(String extension) {
        if (extension == null) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }

        return switch (extension.toLowerCase()) {
            case "mp3" -> MediaType.parseMediaType("audio/mpeg");
            case "flac" -> MediaType.parseMediaType("audio/flac");
            case "m4a", "mp4", "aac" -> MediaType.parseMediaType("audio/mp4");
            case "ogg" -> MediaType.parseMediaType("audio/ogg");
            case "opus" -> MediaType.parseMediaType("audio/opus");
            case "wav" -> MediaType.parseMediaType("audio/wav");
            default -> MediaType.APPLICATION_OCTET_STREAM;
        };
    }
}
