package com.petemarket.server.media;

import com.petemarket.server.common.BusinessException;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * 本地文件存储 — 当 OSS 未启用时，文件存储到服务器本地磁盘，
 * 通过 /media/files/** 路径对外提供访问。
 */
@Service
public class LocalMediaStorageService {
    private static final Logger log = LoggerFactory.getLogger(LocalMediaStorageService.class);

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "jpg", "jpeg", "png", "gif", "webp", "mp4", "mov", "avi", "m4v", "webm"
    );

    @Value("${pet-emarket.media.local-storage-path:./uploads}")
    private String storagePath;

    private Path basePath;

    @PostConstruct
    public void init() {
        basePath = Paths.get(storagePath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(basePath);
            log.info("Local media storage initialized at: {}", basePath);
        } catch (IOException e) {
            log.error("Failed to create local media storage directory: {}", basePath, e);
        }
    }

    public OssUploadResult store(MultipartFile file, MediaType mediaType) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("LOCAL_EMPTY_FILE", "Upload file is empty");
        }
        String originalName = file.getOriginalFilename() == null ? "asset" : file.getOriginalFilename();
        String extension = extension(originalName);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new BusinessException("LOCAL_UNSUPPORTED_FILE", "Unsupported media file type");
        }
        if (mediaType == MediaType.IMAGE && !isImage(extension)) {
            throw new BusinessException("LOCAL_MEDIA_TYPE_MISMATCH", "Image media must use an image file");
        }
        if (mediaType == MediaType.VIDEO && !isVideo(extension)) {
            throw new BusinessException("LOCAL_MEDIA_TYPE_MISMATCH", "Video media must use a video file");
        }

        String folder = mediaType == MediaType.VIDEO ? "video" : "image";
        String date = DateTimeFormatter.BASIC_ISO_DATE.format(LocalDate.now());
        String name = UUID.randomUUID().toString().replace("-", "");
        String fileName = name + "." + extension;

        Path targetDir = basePath.resolve(folder).resolve(date);
        try {
            Files.createDirectories(targetDir);
        } catch (IOException e) {
            throw new BusinessException("LOCAL_STORAGE_ERROR", "Failed to create storage directory", HttpStatus.INTERNAL_SERVER_ERROR);
        }

        Path targetFile = targetDir.resolve(fileName);
        try {
            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);
            log.info("File stored locally: {}", targetFile);
        } catch (IOException e) {
            throw new BusinessException("LOCAL_STORAGE_ERROR", "Failed to store file: " + e.getMessage(), HttpStatus.INTERNAL_SERVER_ERROR);
        }

        String url = "/media/files/" + folder + "/" + date + "/" + fileName;
        return new OssUploadResult(fileName, url, file.getContentType(), file.getSize());
    }

    public Path resolveFilePath(String relativePath) {
        // relativePath 形如 "video/20260706/abc123.mp4"
        return basePath.resolve(relativePath).normalize();
    }

    private String extension(String filename) {
        int index = filename.lastIndexOf('.');
        if (index < 0 || index == filename.length() - 1) {
            throw new BusinessException("LOCAL_UNSUPPORTED_FILE", "Upload file must have an extension");
        }
        return filename.substring(index + 1).toLowerCase(Locale.ROOT);
    }

    private boolean isImage(String extension) {
        return Set.of("jpg", "jpeg", "png", "gif", "webp").contains(extension);
    }

    private boolean isVideo(String extension) {
        return Set.of("mp4", "mov", "avi", "m4v", "webm").contains(extension);
    }
}
