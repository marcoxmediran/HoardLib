package org.mmediran.hoardlib.dto;

import org.mmediran.hoardlib.domain.Track;

public record TrackDto(
    Long id,
    String title,
    Integer trackNumber,
    long fileSizeBytes,
    String extension,
    String streamUrl
) {
    public static TrackDto fromEntity(Track track) {
        return new TrackDto(
            track.getId(),
            track.getTitle(),
            track.getTrackNumber(),
            track.getFileSizeBytes(),
            track.getExtension(),
            "/api/tracks/" + track.getId() + "/stream"
        );
    }
}
