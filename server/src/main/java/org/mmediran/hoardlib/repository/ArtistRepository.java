package org.mmediran.hoardlib.repository;

import org.mmediran.hoardlib.domain.Artist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ArtistRepository extends JpaRepository<Artist, Long> {
    Optional<Artist> findByName(String name);

    @Query("SELECT DISTINCT a FROM Artist a LEFT JOIN FETCH a.albums alb LEFT JOIN FETCH alb.tracks ORDER BY a.name ASC")
    List<Artist> findAllWithAlbumsAndTracks();

    @Query("SELECT DISTINCT a FROM Artist a LEFT JOIN FETCH a.albums alb LEFT JOIN FETCH alb.tracks WHERE a.id = :id")
    Optional<Artist> findByIdWithAlbumsAndTracks(@Param("id") Long id);
}
