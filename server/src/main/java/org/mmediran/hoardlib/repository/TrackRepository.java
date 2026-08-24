package org.mmediran.hoardlib.repository;

import org.mmediran.hoardlib.domain.Track;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TrackRepository extends JpaRepository<Track, Long> {
    Optional<Track> findByFilePath(String filePath);
    List<Track> findByAlbumIdOrderByTrackNumberAsc(Long albumId);
}
