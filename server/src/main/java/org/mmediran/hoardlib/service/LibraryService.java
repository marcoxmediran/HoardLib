package org.mmediran.hoardlib.service;

import org.mmediran.hoardlib.domain.Album;
import org.mmediran.hoardlib.domain.Artist;
import org.mmediran.hoardlib.dto.AlbumDto;
import org.mmediran.hoardlib.dto.ArtistDto;
import org.mmediran.hoardlib.repository.AlbumRepository;
import org.mmediran.hoardlib.repository.ArtistRepository;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class LibraryService {

    private final ArtistRepository artistRepository;
    private final AlbumRepository albumRepository;

    public LibraryService(ArtistRepository artistRepository, AlbumRepository albumRepository) {
        this.artistRepository = artistRepository;
        this.albumRepository = albumRepository;
    }

    public List<ArtistDto> getAllArtists() {
        return artistRepository.findAllWithAlbumsAndTracks().stream()
                .map(ArtistDto::fromEntity)
                .toList();
    }

    public Optional<ArtistDto> getArtistById(Long id) {
        return artistRepository.findByIdWithAlbumsAndTracks(id)
                .map(ArtistDto::fromEntity);
    }

    public List<AlbumDto> getAlbums(Boolean listened) {
        List<Album> albums;
        if (listened != null) {
            albums = albumRepository.findAllByListenedWithArtistAndTracks(listened);
        } else {
            albums = albumRepository.findAllWithArtistAndTracks();
        }
        return albums.stream()
                .map(AlbumDto::fromEntity)
                .toList();
    }

    public Optional<AlbumDto> getAlbumById(Long id) {
        return albumRepository.findByIdWithArtistAndTracks(id)
                .map(AlbumDto::fromEntity);
    }

    @Transactional
    public Optional<AlbumDto> updateAlbumListened(Long id, Boolean explicitListened) {
        return albumRepository.findByIdWithArtistAndTracks(id).map(album -> {
            boolean newListened = (explicitListened != null) ? explicitListened : !album.isListened();
            album.setListened(newListened);
            Album saved = albumRepository.save(album);
            return AlbumDto.fromEntity(saved);
        });
    }

    public Optional<Resource> getAlbumCoverResource(Long albumId) {
        return albumRepository.findById(albumId).flatMap(album -> {
            String coverPath = album.getCoverPath();
            if (coverPath == null) {
                return Optional.empty();
            }
            File file = new File(coverPath);
            if (!file.exists() || !file.isFile()) {
                return Optional.empty();
            }
            return Optional.of(new FileSystemResource(file));
        });
    }
}
