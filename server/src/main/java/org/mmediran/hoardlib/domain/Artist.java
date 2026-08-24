package org.mmediran.hoardlib.domain;

import jakarta.persistence.*;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "artists")
public class Artist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @OneToMany(mappedBy = "artist", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("year ASC, title ASC")
    private Set<Album> albums = new LinkedHashSet<>();

    public Artist() {
    }

    public Artist(String name) {
        this.name = name;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Set<Album> getAlbums() {
        return albums;
    }

    public void setAlbums(Set<Album> albums) {
        if (this.albums == null) {
            this.albums = new LinkedHashSet<>();
        } else {
            this.albums.clear();
        }
        if (albums != null) {
            this.albums.addAll(albums);
        }
    }

    public void addAlbum(Album album) {
        albums.add(album);
        album.setArtist(this);
    }
}
