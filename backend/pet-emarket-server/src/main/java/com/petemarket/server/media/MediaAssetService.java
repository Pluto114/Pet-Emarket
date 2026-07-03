package com.petemarket.server.media;

import com.petemarket.server.common.BusinessException;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class MediaAssetService {
    private final MediaAssetRepository mediaAssetRepository;
    private final OssStorageService ossStorageService;

    public MediaAssetService(MediaAssetRepository mediaAssetRepository, OssStorageService ossStorageService) {
        this.mediaAssetRepository = mediaAssetRepository;
        this.ossStorageService = ossStorageService;
    }

    @Transactional(readOnly = true)
    public List<MediaAssetResponse> list(boolean includeAll, MediaStatus status, String keyword) {
        List<MediaAsset> assets = includeAll
                ? mediaAssetRepository.findAll()
                : mediaAssetRepository.findByStatusOrderByCreatedAtDesc(MediaStatus.APPROVED);
        String normalizedKeyword = keyword == null ? "" : keyword.trim().toLowerCase(Locale.ROOT);
        return assets.stream()
                .filter(asset -> status == null || asset.getStatus() == status)
                .filter(asset -> matchesKeyword(asset, normalizedKeyword))
                .sorted(Comparator.comparing(MediaAsset::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder())).reversed())
                .map(MediaAssetResponse::from)
                .toList();
    }

    @Transactional
    public MediaAssetResponse create(UpsertMediaAssetRequest request, Long operatorId) {
        MediaAsset asset = new MediaAsset();
        asset.setCreatedBy(operatorId);
        apply(asset, request);
        mediaAssetRepository.save(asset);
        return MediaAssetResponse.from(asset);
    }

    @Transactional
    public MediaAssetResponse upload(String title,
                                     MediaType mediaType,
                                     Long productId,
                                     String description,
                                     MultipartFile file,
                                     MultipartFile coverFile,
                                     Long operatorId) {
        MediaType safeType = mediaType == null ? MediaType.IMAGE : mediaType;
        OssUploadResult main = ossStorageService.upload(file, safeType);
        OssUploadResult cover = coverFile == null || coverFile.isEmpty()
                ? null
                : ossStorageService.upload(coverFile, MediaType.IMAGE);

        MediaAsset asset = new MediaAsset();
        asset.setCreatedBy(operatorId);
        asset.setTitle(defaultText(title, defaultText(file.getOriginalFilename(), "OSS Media Asset")));
        asset.setMediaType(safeType);
        asset.setUrl(main.url());
        asset.setCoverUrl(cover == null ? "" : cover.url());
        asset.setProductId(productId);
        asset.setDescription(defaultText(description, ""));
        asset.setStatus(MediaStatus.PENDING);
        asset.setAuditRemark("");
        mediaAssetRepository.save(asset);
        return MediaAssetResponse.from(asset);
    }

    @Transactional
    public MediaAssetResponse update(Long id, UpsertMediaAssetRequest request) {
        MediaAsset asset = find(id);
        apply(asset, request);
        return MediaAssetResponse.from(asset);
    }

    @Transactional
    public MediaAssetResponse audit(Long id, boolean approved, String remark, Long auditorId) {
        MediaAsset asset = find(id);
        asset.setStatus(approved ? MediaStatus.APPROVED : MediaStatus.REJECTED);
        asset.setAuditRemark(defaultText(remark, approved ? "Media approved" : "Media rejected"));
        asset.setAuditedBy(auditorId);
        asset.setAuditedAt(Instant.now());
        return MediaAssetResponse.from(asset);
    }

    @Transactional
    public void delete(Long id) {
        mediaAssetRepository.delete(find(id));
    }

    private MediaAsset find(Long id) {
        return mediaAssetRepository.findById(id)
                .orElseThrow(() -> new BusinessException("200404", "Media asset not found", HttpStatus.NOT_FOUND));
    }

    private void apply(MediaAsset asset, UpsertMediaAssetRequest request) {
        asset.setTitle(request.title());
        asset.setMediaType(request.mediaType() == null ? MediaType.IMAGE : request.mediaType());
        asset.setUrl(request.url());
        asset.setCoverUrl(defaultText(request.coverUrl(), ""));
        asset.setProductId(request.productId());
        asset.setDescription(defaultText(request.description(), ""));
        asset.setStatus(request.status() == null ? MediaStatus.PENDING : request.status());
        asset.setAuditRemark(defaultText(request.auditRemark(), ""));
    }

    private boolean matchesKeyword(MediaAsset asset, String keyword) {
        if (keyword.isBlank()) {
            return true;
        }
        String searchable = (asset.getTitle() + " " + asset.getDescription() + " " + asset.getUrl()).toLowerCase(Locale.ROOT);
        return searchable.contains(keyword);
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
