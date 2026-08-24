package org.mmediran.hoardlib.controller;

import org.mmediran.hoardlib.dto.ArtistDto;
import org.mmediran.hoardlib.service.LibraryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/artists")
public class ArtistController {

    private final LibraryService libraryService;

    public ArtistController(LibraryService libraryService) {
        this.libraryService = libraryService;
    }

    @GetMapping
    public List<ArtistDto> getAllArtists() {
        return libraryService.getAllArtists();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ArtistDto> getArtistById(@PathVariable Long id) {
        return libraryService.getArtistById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
