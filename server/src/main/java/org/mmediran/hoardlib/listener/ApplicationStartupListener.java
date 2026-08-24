package org.mmediran.hoardlib.listener;

import org.mmediran.hoardlib.service.LibraryScannerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class ApplicationStartupListener {

    private static final Logger log = LoggerFactory.getLogger(ApplicationStartupListener.class);
    private final LibraryScannerService libraryScannerService;

    public ApplicationStartupListener(LibraryScannerService libraryScannerService) {
        this.libraryScannerService = libraryScannerService;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        log.info("Application ready. Triggering initial library scan...");
        try {
            libraryScannerService.scanLibrary();
        } catch (Exception e) {
            log.error("Initial library scan failed during startup", e);
        }
    }
}
