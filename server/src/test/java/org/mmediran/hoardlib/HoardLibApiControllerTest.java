package org.mmediran.hoardlib;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mmediran.hoardlib.domain.Album;
import org.mmediran.hoardlib.domain.Artist;
import org.mmediran.hoardlib.domain.Track;
import org.mmediran.hoardlib.repository.AlbumRepository;
import org.mmediran.hoardlib.repository.ArtistRepository;
import org.mmediran.hoardlib.repository.TrackRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class HoardLibApiControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private AlbumRepository albumRepository;

    @Autowired
    private TrackRepository trackRepository;

    @TempDir
    Path tempDir;

    private Artist artist;
    private Album album1;
    private Album album2;
    private Track track1;
    private Path coverFile;
    private Path audioFile;

    @BeforeEach
    void setUp() throws IOException {
        artistRepository.deleteAll();

        // Create sample audio file
        audioFile = tempDir.resolve("01. Pump Up the Love.mp3");
        Files.writeString(audioFile, "0123456789ABCDEF0123456789ABCDEF");

        // Create sample cover file
        coverFile = tempDir.resolve("cover.jpg");
        Files.writeString(coverFile, "JPEG_MOCK_IMAGE_DATA");

        // Seed data
        artist = new Artist("2 Mello");

        album1 = new Album("Memories of Tokyo-To", 2018, artist);
        album1.setCoverPath(coverFile.toAbsolutePath().toString());
        album1.setListened(false);

        track1 = new Track("Pump Up the Love", 1, audioFile.toAbsolutePath().toString(),
                Files.size(audioFile), "mp3", album1);
        album1.addTrack(track1);

        album2 = new Album("Sounds of Tokyo-To Future", 2021, artist);
        album2.setListened(true);

        artist.addAlbum(album1);
        artist.addAlbum(album2);
        artist = artistRepository.save(artist);

        album1 = artist.getAlbums().stream().filter(a -> a.getTitle().equals("Memories of Tokyo-To")).findFirst().orElseThrow();
        album2 = artist.getAlbums().stream().filter(a -> a.getTitle().equals("Sounds of Tokyo-To Future")).findFirst().orElseThrow();
        track1 = album1.getTracks().iterator().next();
    }

    @Test
    void testGetArtists() throws Exception {
        mockMvc.perform(get("/api/artists"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name", is("2 Mello")))
                .andExpect(jsonPath("$[0].albums", hasSize(2)));
    }

    @Test
    void testGetArtistById() throws Exception {
        mockMvc.perform(get("/api/artists/" + artist.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name", is("2 Mello")))
                .andExpect(jsonPath("$.albums", hasSize(2)));
    }

    @Test
    void testGetAlbumsFilteringByListened() throws Exception {
        // All albums
        mockMvc.perform(get("/api/albums"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));

        // Unlistened albums
        mockMvc.perform(get("/api/albums").param("listened", "false"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].title", is("Memories of Tokyo-To")))
                .andExpect(jsonPath("$[0].listened", is(false)))
                .andExpect(jsonPath("$[0].tracks", hasSize(1)));

        // Listened albums
        mockMvc.perform(get("/api/albums").param("listened", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].title", is("Sounds of Tokyo-To Future")))
                .andExpect(jsonPath("$[0].listened", is(true)));
    }

    @Test
    void testGetAlbumById() throws Exception {
        mockMvc.perform(get("/api/albums/" + album1.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title", is("Memories of Tokyo-To")))
                .andExpect(jsonPath("$.year", is(2018)))
                .andExpect(jsonPath("$.hasCover", is(true)))
                .andExpect(jsonPath("$.coverUrl", is("/api/albums/" + album1.getId() + "/cover")))
                .andExpect(jsonPath("$.downloadUrl", is("/api/albums/" + album1.getId() + "/download")))
                .andExpect(jsonPath("$.tracks[0].title", is("Pump Up the Love")))
                .andExpect(jsonPath("$.tracks[0].streamUrl", is("/api/tracks/" + track1.getId() + "/stream")));
    }

    @Test
    void testUpdateAlbumListenedStatus() throws Exception {
        // Explicit JSON body
        mockMvc.perform(patch("/api/albums/" + album1.getId() + "/listened")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"listened\": true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.listened", is(true)));

        Album updated = albumRepository.findById(album1.getId()).orElseThrow();
        assertThat(updated.isListened()).isTrue();

        // Empty body -> toggles from true to false
        mockMvc.perform(patch("/api/albums/" + album1.getId() + "/listened"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.listened", is(false)));

        Album toggled = albumRepository.findById(album1.getId()).orElseThrow();
        assertThat(toggled.isListened()).isFalse();

        // Query param -> sets explicitly
        mockMvc.perform(patch("/api/albums/" + album1.getId() + "/listened").param("listened", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.listened", is(true)));
    }

    @Test
    void testGetAlbumCover() throws Exception {
        mockMvc.perform(get("/api/albums/" + album1.getId() + "/cover"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, MediaType.IMAGE_JPEG_VALUE))
                .andExpect(header().exists(HttpHeaders.CACHE_CONTROL))
                .andExpect(content().string("JPEG_MOCK_IMAGE_DATA"));
    }

    @Test
    void testTrackAudioStreamingFullAndRange() throws Exception {
        // Full stream
        mockMvc.perform(get("/api/tracks/" + track1.getId() + "/stream"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCEPT_RANGES, "bytes"))
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, "audio/mpeg"));

        // Partial range stream (e.g. bytes=0-9)
        mockMvc.perform(get("/api/tracks/" + track1.getId() + "/stream")
                        .header(HttpHeaders.RANGE, "bytes=0-9"))
                .andExpect(status().isPartialContent())
                .andExpect(header().string(HttpHeaders.ACCEPT_RANGES, "bytes"))
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, "audio/mpeg"));
    }

    @Test
    void testAlbumZipDownload() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/albums/" + album1.getId() + "/download"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, "application/zip"))
                .andExpect(header().exists(HttpHeaders.CONTENT_DISPOSITION))
                .andReturn();

        byte[] zipBytes = result.getResponse().getContentAsByteArray();
        assertThat(zipBytes).isNotEmpty();

        List<String> entryNames = new ArrayList<>();
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(zipBytes))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                entryNames.add(entry.getName());
                zis.closeEntry();
            }
        }

        assertThat(entryNames).contains("01. Pump Up the Love.mp3", "cover.jpg");
    }

    @Test
    void testManualScanEndpoint() throws Exception {
        mockMvc.perform(post("/api/library/scan"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", notNullValue()));
    }
}
