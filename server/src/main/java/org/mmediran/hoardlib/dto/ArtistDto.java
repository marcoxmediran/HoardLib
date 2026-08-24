package org.mmediran.hoardlib.dto;

import org.mmediran.hoardlib.domain.Album;
import java.util.Comparator;
import java.util.List;

public record ArtistDto(
    Long id,
    String name,
    List<AlbumDto> albums
) {
    public static ArtistDto fromEntity(org.mmediran.hoardlib.domain.Artist artist) {
        List<AlbumDto> albumDtos = artist.getAlbums() != null
            ? artist.getAlbums().stream()
                .sorted(Comparator.comparing(Album::getYear, Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(Album::getTitle, Comparator.nullsLast(String::compareTo)))
                .map(AlbumDto::fromEntity)
                .toList()
            : List.of();

        return new ArtistDto(
            artist.getId(),
            artist.getName(),
            albumDtos
        );
    }
}
