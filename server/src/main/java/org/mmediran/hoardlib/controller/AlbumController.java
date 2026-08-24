package org.mmediran.hoardlib.controller;

import org.mmediran.hoardlib.dto.AlbumDto;
import org.mmediran.hoardlib.dto.ListenedUpdateRequest;
import org.mmediran.hoardlib.service.AlbumDownloadService;
import org.mmediran.hoardlib.service.LibraryService;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import java.util.List;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/albums")
public class AlbumController {

    private final LibraryService libraryService;
    private final AlbumDownloadService albumDownloadService;

    public AlbumController(LibraryService libraryService, AlbumDownloadService albumDownloadService) {
        this.libraryService = libraryService;
        this.albumDownloadService = albumDownloadService;
    }

    @GetMapping
    public List<AlbumDto> getAlbums(@RequestParam(name = "listened", required = false) Boolean listened) {
        return libraryService.getAlbums(listened);
    }

    @GetMapping("/{id}")
    public ResponseEntity<AlbumDto> getAlbumById(@PathVariable Long id) {
        return libraryService.getAlbumById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/listened")
    public ResponseEntity<AlbumDto> updateListened(
            @PathVariable Long id,
            @RequestParam(name = "listened", required = false) Boolean listenedParam,
            @RequestBody(required = false) ListenedUpdateRequest request
    ) {
        Boolean listenedValue = null;
        if (request != null && request.listened() != null) {
            listenedValue = request.listened();
        } else if (listenedParam != null) {
            listenedValue = listenedParam;
        }
        return libraryService.updateAlbumListened(id, listenedValue)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/cover")
    public ResponseEntity<Resource> getAlbumCover(@PathVariable Long id) {
        return libraryService.getAlbumCoverResource(id)
                .map(resource -> ResponseEntity.ok()
                        .contentType(MediaType.IMAGE_JPEG)
                        .cacheControl(CacheControl.maxAge(7, TimeUnit.DAYS).cachePublic())
                        .body(resource))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<StreamingResponseBody> downloadAlbum(@PathVariable Long id) {
        return albumDownloadService.downloadAlbumZip(id);
    }
}
