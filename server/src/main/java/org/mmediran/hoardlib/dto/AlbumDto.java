package org.mmediran.hoardlib.dto;

import org.mmediran.hoardlib.domain.Album;
import org.mmediran.hoardlib.domain.Track;
import java.util.Comparator;
import java.util.List;

public record AlbumDto(
    Long id,
    String title,
    Integer year,
    boolean listened,
    boolean hasCover,
    String coverUrl,
    String downloadUrl,
    String artistName,
    Long artistId,
    List<TrackDto> tracks
) {
    public static AlbumDto fromEntity(Album album) {
        boolean hasCover = album.getCoverPath() != null;
        List<TrackDto> trackDtos = album.getTracks() != null
            ? album.getTracks().stream()
                .sorted(Comparator.comparing(Track::getTrackNumber, Comparator.nullsLast(Integer::compareTo)))
                .map(TrackDto::fromEntity)
                .toList()
            : List.of();

        return new AlbumDto(
            album.getId(),
            album.getTitle(),
            album.getYear(),
            album.isListened(),
            hasCover,
            hasCover ? "/api/albums/" + album.getId() + "/cover" : null,
            "/api/albums/" + album.getId() + "/download",
            album.getArtist() != null ? album.getArtist().getName() : null,
            album.getArtist() != null ? album.getArtist().getId() : null,
            trackDtos
        );
    }
}
