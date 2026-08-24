package org.mmediran.hoardlib.controller;

import org.mmediran.hoardlib.service.AudioStreamService;
import org.springframework.core.io.support.ResourceRegion;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/tracks")
public class TrackController {

    private final AudioStreamService audioStreamService;

    public TrackController(AudioStreamService audioStreamService) {
        this.audioStreamService = audioStreamService;
    }

    @GetMapping("/{id}/stream")
    public ResponseEntity<ResourceRegion> streamTrack(
            @PathVariable Long id,
            @RequestHeader HttpHeaders headers
    ) {
        return audioStreamService.streamTrack(id, headers);
    }
}
