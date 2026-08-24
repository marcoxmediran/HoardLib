package org.mmediran.hoardlib.repository;

import org.mmediran.hoardlib.domain.Album;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AlbumRepository extends JpaRepository<Album, Long> {
    List<Album> findByListened(boolean listened);

    @Query("SELECT DISTINCT a FROM Album a JOIN a.artist art LEFT JOIN FETCH a.tracks WHERE a.title = :title AND art.name = :artistName")
    Optional<Album> findByTitleAndArtistName(@Param("title") String title, @Param("artistName") String artistName);

    @Query("SELECT DISTINCT a FROM Album a JOIN FETCH a.artist LEFT JOIN FETCH a.tracks ORDER BY a.artist.name ASC, a.year ASC, a.title ASC")
    List<Album> findAllWithArtistAndTracks();

    @Query("SELECT DISTINCT a FROM Album a JOIN FETCH a.artist LEFT JOIN FETCH a.tracks WHERE a.listened = :listened ORDER BY a.artist.name ASC, a.year ASC, a.title ASC")
    List<Album> findAllByListenedWithArtistAndTracks(@Param("listened") boolean listened);

    @Query("SELECT DISTINCT a FROM Album a JOIN FETCH a.artist LEFT JOIN FETCH a.tracks WHERE a.id = :id")
    Optional<Album> findByIdWithArtistAndTracks(@Param("id") Long id);
}
