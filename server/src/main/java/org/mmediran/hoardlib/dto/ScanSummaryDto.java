package org.mmediran.hoardlib.dto;

public record ScanSummaryDto(
    int artistsScanned,
    int albumsScanned,
    int tracksScanned,
    long durationMs,
    String status
) {
}
