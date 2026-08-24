package org.mmediran.hoardlib;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mmediran.hoardlib.domain.Album;
import org.mmediran.hoardlib.domain.Artist;
import org.mmediran.hoardlib.domain.Track;
import org.mmediran.hoardlib.dto.ScanSummaryDto;
import org.mmediran.hoardlib.repository.AlbumRepository;
import org.mmediran.hoardlib.repository.ArtistRepository;
import org.mmediran.hoardlib.repository.TrackRepository;
import org.mmediran.hoardlib.service.LibraryScannerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class LibraryScannerServiceTest {

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private AlbumRepository albumRepository;

    @Autowired
    private TrackRepository trackRepository;

    @TempDir
    Path tempMusicDir;

    private LibraryScannerService scannerService;

    @BeforeEach
    void setUp() {
        artistRepository.deleteAll();

        scannerService = new LibraryScannerService(
                tempMusicDir.toAbsolutePath().toString(),
                artistRepository,
                albumRepository,
                trackRepository
        );
    }

    @Test
    void testScanLibraryAndPreserveListenedState() throws IOException {
        // Create library structure:
        // tempMusicDir/10cc/The Original Soundtrack (2006)/01. Une Nuit a Paris.mp3
        // tempMusicDir/10cc/The Original Soundtrack (2006)/cover.jpg
        Path artistDir = Files.createDirectories(tempMusicDir.resolve("10cc"));
        Path albumDir = Files.createDirectories(artistDir.resolve("The Original Soundtrack (2006)"));
        Path track1 = albumDir.resolve("01. Une Nuit a Paris.mp3");
        Files.writeString(track1, "fake mp3 data 1");
        Path track2 = albumDir.resolve("02. I'm Not in Love.mp3");
        Files.writeString(track2, "fake mp3 data 2");
        Path cover = albumDir.resolve("cover.jpg");
        Files.writeString(cover, "fake cover image");

        // First scan
        ScanSummaryDto scan1 = scannerService.scanLibrary();
        assertThat(scan1.artistsScanned()).isEqualTo(1);
        assertThat(scan1.albumsScanned()).isEqualTo(1);
        assertThat(scan1.tracksScanned()).isEqualTo(2);

        List<Artist> artists = artistRepository.findAllWithAlbumsAndTracks();
        assertThat(artists).hasSize(1);
        Artist artist = artists.get(0);
        assertThat(artist.getName()).isEqualTo("10cc");
        assertThat(artist.getAlbums()).hasSize(1);

        Album album = artist.getAlbums().iterator().next();
        assertThat(album.getTitle()).isEqualTo("The Original Soundtrack");
        assertThat(album.getYear()).isEqualTo(2006);
        assertThat(album.isListened()).isFalse();
        assertThat(album.getCoverPath()).isEqualTo(cover.toAbsolutePath().toString());
        assertThat(album.getTracks()).hasSize(2);
        Track firstTrack = album.getTracks().iterator().next();
        assertThat(firstTrack.getTitle()).isEqualTo("Une Nuit a Paris");
        assertThat(firstTrack.getTrackNumber()).isEqualTo(1);
        assertThat(firstTrack.getExtension()).isEqualTo("mp3");

        // Mark album as listened
        album.setListened(true);
        albumRepository.save(album);

        // Add a 3rd track
        Path track3 = albumDir.resolve("03. Blackmail.mp3");
        Files.writeString(track3, "fake mp3 data 3");

        // Rescan
        ScanSummaryDto scan2 = scannerService.scanLibrary();
        assertThat(scan2.tracksScanned()).isEqualTo(3);

        Album reloadedAlbum = albumRepository.findByTitleAndArtistName("The Original Soundtrack", "10cc").orElseThrow();
        assertThat(reloadedAlbum.isListened()).isTrue(); // PRESERVED!
        assertThat(reloadedAlbum.getTracks()).hasSize(3);
    }

    @Test
    void testScanMultipleArtistsAndAlbums() throws IOException {
        // Artist 1
        Path artist1Dir = Files.createDirectories(tempMusicDir.resolve("10cc"));
        Path album1Dir = Files.createDirectories(artist1Dir.resolve("The Original Soundtrack (2006)"));
        Files.writeString(album1Dir.resolve("01. Une Nuit a Paris.mp3"), "audio1");

        // Artist 2
        Path artist2Dir = Files.createDirectories(tempMusicDir.resolve("2 Mello"));
        Path album2Dir = Files.createDirectories(artist2Dir.resolve("Memories of Tokyo-To (2018)"));
        Files.writeString(album2Dir.resolve("01. Pump Up the Love.mp3"), "audio2");
        Files.writeString(album2Dir.resolve("02. Here I Go.mp3"), "audio3");

        ScanSummaryDto scan = scannerService.scanLibrary();
        assertThat(scan.artistsScanned()).isEqualTo(2);
        assertThat(scan.albumsScanned()).isEqualTo(2);
        assertThat(scan.tracksScanned()).isEqualTo(3);
        assertThat(scan.status()).isEqualTo("SUCCESS");

        // Run rescan to ensure multiple artists in a single transaction execute cleanly
        ScanSummaryDto rescan = scannerService.scanLibrary();
        assertThat(rescan.artistsScanned()).isEqualTo(2);
        assertThat(rescan.albumsScanned()).isEqualTo(2);
        assertThat(rescan.tracksScanned()).isEqualTo(3);
        assertThat(rescan.status()).isEqualTo("SUCCESS");
    }

    @Test
    void testScanDateFormattedFoldersAndOpusTracks() throws IOException {
        // Test exact pattern from user's missed tracks
        Path artistDir = Files.createDirectories(tempMusicDir.resolve("Ponpon Chen Peng Xuan"));
        Path albumDir = Files.createDirectories(artistDir.resolve("Ponpon_But Not For Me (Live) (20250409)"));
        Path trackFile = albumDir.resolve("00. Ponpon_But Not For Me (Live).opus");
        Files.writeString(trackFile, "fake opus audio data");

        Path longArtistDir = Files.createDirectories(tempMusicDir.resolve("neibeo Now_"));
        Path longAlbumDir = Files.createDirectories(longArtistDir.resolve("[yaganhabjusil] jon bag & amhojunjae - 'Disco Yes (feat. Poppy Ajudha)' jeugheunghabju raibeu! _ yaganjageobsil (20210830)"));
        Path longTrackFile = longAlbumDir.resolve("00. [yaganhabjusil] jon bag & amhojunjae - 'Disco Yes (feat. Poppy Ajudha)' jeugheunghabju raibeu! _ yaganjageobsil.opus");
        Files.writeString(longTrackFile, "fake long opus audio data");

        ScanSummaryDto scan = scannerService.scanLibrary();
        assertThat(scan.artistsScanned()).isEqualTo(2);
        assertThat(scan.albumsScanned()).isEqualTo(2);
        assertThat(scan.tracksScanned()).isEqualTo(2);

        Album album = albumRepository.findByTitleAndArtistName("Ponpon_But Not For Me (Live)", "Ponpon Chen Peng Xuan").orElseThrow();
        assertThat(album.getYear()).isEqualTo(2025);
        assertThat(album.getTracks()).hasSize(1);
        Track track = album.getTracks().iterator().next();
        assertThat(track.getTrackNumber()).isEqualTo(0);
        assertThat(track.getExtension()).isEqualTo("opus");
        assertThat(track.getTitle()).isEqualTo("Ponpon_But Not For Me (Live)");
    }
}
