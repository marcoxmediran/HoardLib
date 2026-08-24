package org.mmediran.hoardlib.controller;

import org.mmediran.hoardlib.dto.ScanSummaryDto;
import org.mmediran.hoardlib.service.LibraryScannerService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/library")
public class LibraryController {

    private final LibraryScannerService libraryScannerService;

    public LibraryController(LibraryScannerService libraryScannerService) {
        this.libraryScannerService = libraryScannerService;
    }

    @PostMapping("/scan")
    public ResponseEntity<ScanSummaryDto> scanLibrary() {
        ScanSummaryDto result = libraryScannerService.scanLibrary();
        return ResponseEntity.ok(result);
    }
}
