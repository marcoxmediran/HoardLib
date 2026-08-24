package org.mmediran.hoardlib.domain;

import jakarta.persistence.*;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "albums", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"artist_id", "title"})
})
public class Album {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    private Integer year;

    private String coverPath;

    @Column(nullable = false)
    private boolean listened = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "artist_id", nullable = false)
    private Artist artist;

    @OneToMany(mappedBy = "album", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("trackNumber ASC, title ASC")
    private Set<Track> tracks = new LinkedHashSet<>();

    public Album() {
    }

    public Album(String title, Integer year, Artist artist) {
        this.title = title;
        this.year = year;
        this.artist = artist;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public Integer getYear() {
        return year;
    }

    public void setYear(Integer year) {
        this.year = year;
    }

    public String getCoverPath() {
        return coverPath;
    }

    public void setCoverPath(String coverPath) {
        this.coverPath = coverPath;
    }

    public boolean isListened() {
        return listened;
    }

    public void setListened(boolean listened) {
        this.listened = listened;
    }

    public Artist getArtist() {
        return artist;
    }

    public void setArtist(Artist artist) {
        this.artist = artist;
    }

    public Set<Track> getTracks() {
        return tracks;
    }

    public void setTracks(Set<Track> tracks) {
        if (this.tracks == null) {
            this.tracks = new LinkedHashSet<>();
        } else {
            this.tracks.clear();
        }
        if (tracks != null) {
            this.tracks.addAll(tracks);
        }
    }

    public void addTrack(Track track) {
        tracks.add(track);
        track.setAlbum(this);
    }
}
