package com.petemarket.server.media;

import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.ObjectMetadata;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.config.PetEmarketProperties;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class OssStorageService {
    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "jpg", "jpeg", "png", "gif", "webp", "mp4", "mov", "avi", "m4v", "webm"
    );
    private final PetEmarketProperties properties;

    public OssStorageService(PetEmarketProperties properties) {
        this.properties = properties;
    }

    public boolean isEnabled() {
        return properties.getOss().isEnabled()
                && !blank(properties.getOss().getEndpoint())
                && !blank(properties.getOss().getBucket())
                && !blank(properties.getOss().getAccessKeyId())
                && !blank(properties.getOss().getAccessKeySecret());
    }

    public OssUploadResult upload(MultipartFile file, MediaType mediaType) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException("OSS_EMPTY_FILE", "Upload file is empty");
        }
        PetEmarketProperties.Oss config = properties.getOss();
        requireConfigured(config);
        String originalName = file.getOriginalFilename() == null ? "asset" : file.getOriginalFilename();
        String extension = extension(originalName);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new BusinessException("OSS_UNSUPPORTED_FILE", "Unsupported media file type");
        }
        if (mediaType == MediaType.IMAGE && !isImage(extension)) {
            throw new BusinessException("OSS_MEDIA_TYPE_MISMATCH", "Image media must use an image file");
        }
        if (mediaType == MediaType.VIDEO && !isVideo(extension)) {
            throw new BusinessException("OSS_MEDIA_TYPE_MISMATCH", "Video media must use a video file");
        }

        String objectKey = objectKey(config, mediaType, extension);
        ObjectMetadata metadata = new ObjectMetadata();
        metadata.setContentLength(file.getSize());
        if (file.getContentType() != null && !file.getContentType().isBlank()) {
            metadata.setContentType(file.getContentType());
        }

        OSS client = new OSSClientBuilder().build(
                normalizedEndpoint(config.getEndpoint()),
                config.getAccessKeyId(),
                config.getAccessKeySecret()
        );
        try {
            client.putObject(config.getBucket(), objectKey, file.getInputStream(), metadata);
            return new OssUploadResult(objectKey, publicUrl(config, objectKey), file.getContentType(), file.getSize());
        } catch (IOException exception) {
            throw new BusinessException("OSS_UPLOAD_FAILED", "Failed to read upload file", HttpStatus.BAD_REQUEST);
        } catch (RuntimeException exception) {
            throw new BusinessException("OSS_UPLOAD_FAILED", "Failed to upload to OSS: " + exception.getMessage(), HttpStatus.BAD_GATEWAY);
        } finally {
            client.shutdown();
        }
    }

    private void requireConfigured(PetEmarketProperties.Oss config) {
        if (!config.isEnabled()) {
            throw new BusinessException("OSS_DISABLED", "OSS 上传未启用，请配置 OSS_ENABLED=true", HttpStatus.SERVICE_UNAVAILABLE);
        }
        if (blank(config.getEndpoint()) || blank(config.getBucket())) {
            throw new BusinessException("OSS_NOT_CONFIGURED", "OSS endpoint 和 bucket 不能为空", HttpStatus.SERVICE_UNAVAILABLE);
        }
        if (blank(config.getAccessKeyId()) || blank(config.getAccessKeySecret())) {
            throw new BusinessException("OSS_NOT_CONFIGURED", "OSS AccessKeyId/AccessKeySecret 不能为空", HttpStatus.SERVICE_UNAVAILABLE);
        }
    }

    private String objectKey(PetEmarketProperties.Oss config, MediaType mediaType, String extension) {
        String prefix = trimSlashes(config.getObjectPrefix());
        String folder = mediaType == MediaType.VIDEO ? "video" : "image";
        String date = DateTimeFormatter.BASIC_ISO_DATE.format(LocalDate.now());
        String name = UUID.randomUUID().toString().replace("-", "");
        return (prefix.isBlank() ? "" : prefix + "/") + folder + "/" + date + "/" + name + "." + extension;
    }

    private String publicUrl(PetEmarketProperties.Oss config, String objectKey) {
        if (!blank(config.getPublicBaseUrl())) {
            return trimTrailingSlash(config.getPublicBaseUrl()) + "/" + objectKey;
        }
        String endpoint = config.getEndpoint().replaceFirst("^https?://", "");
        return "https://" + config.getBucket() + "." + trimTrailingSlash(endpoint) + "/" + objectKey;
    }

    private String normalizedEndpoint(String endpoint) {
        String trimmed = trimTrailingSlash(endpoint == null ? "" : endpoint.trim());
        if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
            return trimmed;
        }
        return "https://" + trimmed;
    }

    private String extension(String filename) {
        int index = filename.lastIndexOf('.');
        if (index < 0 || index == filename.length() - 1) {
            throw new BusinessException("OSS_UNSUPPORTED_FILE", "Upload file must have an extension");
        }
        return filename.substring(index + 1).toLowerCase(Locale.ROOT);
    }

    private boolean isImage(String extension) {
        return Set.of("jpg", "jpeg", "png", "gif", "webp").contains(extension);
    }

    private boolean isVideo(String extension) {
        return Set.of("mp4", "mov", "avi", "m4v", "webm").contains(extension);
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private String trimSlashes(String value) {
        if (value == null) {
            return "";
        }
        return value.replaceAll("^/+", "").replaceAll("/+$", "");
    }

    private String trimTrailingSlash(String value) {
        return value == null ? "" : value.replaceAll("/+$", "");
    }
}
