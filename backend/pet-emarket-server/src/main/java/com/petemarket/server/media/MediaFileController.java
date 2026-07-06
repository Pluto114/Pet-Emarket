package com.petemarket.server.media;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.nio.file.Path;

/**
 * 本地文件访问控制器 — 提供 /media/files/** 路径的文件访问。
 * 当 OSS 未启用时，上传的文件通过此控制器对外暴露。
 */
@RestController
public class MediaFileController {

    private final LocalMediaStorageService localMediaStorageService;

    public MediaFileController(LocalMediaStorageService localMediaStorageService) {
        this.localMediaStorageService = localMediaStorageService;
    }

    /**
     * 访问路径：/media/files/{type}/{date}/{filename}
     * 例如：/media/files/video/20260706/abc123.mp4
     */
    @GetMapping("/media/files/{type}/{date}/{filename}")
    public ResponseEntity<Resource> serveFile(
            @PathVariable String type,
            @PathVariable String date,
            @PathVariable String filename) {
        String relativePath = type + "/" + date + "/" + filename;
        Path filePath = localMediaStorageService.resolveFilePath(relativePath);
        Resource resource = new FileSystemResource(filePath);
        if (!resource.exists() || !resource.isReadable()) {
            return ResponseEntity.notFound().build();
        }

        MediaType mediaType = resolveMediaType(filename);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                .contentType(mediaType)
                .body(resource);
    }

    private MediaType resolveMediaType(String filename) {
        String lower = filename.toLowerCase();
        if (lower.endsWith(".mp4") || lower.endsWith(".m4v")) return MediaType.valueOf("video/mp4");
        if (lower.endsWith(".mov")) return MediaType.valueOf("video/quicktime");
        if (lower.endsWith(".avi")) return MediaType.valueOf("video/x-msvideo");
        if (lower.endsWith(".webm")) return MediaType.valueOf("video/webm");
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return MediaType.IMAGE_JPEG;
        if (lower.endsWith(".png")) return MediaType.IMAGE_PNG;
        if (lower.endsWith(".gif")) return MediaType.IMAGE_GIF;
        if (lower.endsWith(".webp")) return MediaType.valueOf("image/webp");
        return MediaType.APPLICATION_OCTET_STREAM;
    }
}
