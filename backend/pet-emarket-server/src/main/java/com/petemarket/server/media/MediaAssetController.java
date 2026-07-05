package com.petemarket.server.media;

import java.util.List;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.common.PageData;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/media")
public class MediaAssetController {
    private final MediaAssetService mediaAssetService;

    public MediaAssetController(MediaAssetService mediaAssetService) {
        this.mediaAssetService = mediaAssetService;
    }

    /** Public: get approved media for a product (no auth required for browsing) */
    @GetMapping("/product/{productId}")
    public ApiResponse<List<MediaAssetResponse>> listByProduct(@PathVariable Long productId) {
        return ApiResponse.ok(mediaAssetService.listByProduct(productId));
    }

    @GetMapping
    public ApiResponse<PageData<MediaAssetResponse>> list(@AuthenticationPrincipal UserAccount currentUser,
                                                          @RequestParam(required = false) MediaStatus status,
                                                          @RequestParam(required = false) String keyword) {
        boolean includeAll = isMediaManager(currentUser);
        return ApiResponse.ok(PageData.of(mediaAssetService.list(includeAll, status, keyword)));
    }

    @PostMapping
    public ApiResponse<MediaAssetResponse> create(@AuthenticationPrincipal UserAccount currentUser,
                                                  @Valid @RequestBody UpsertMediaAssetRequest request) {
        requireMediaManager(currentUser);
        return ApiResponse.ok(mediaAssetService.create(request, currentUser.getId()), "media created");
    }

    @PostMapping(value = "/upload", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<MediaAssetResponse> upload(@AuthenticationPrincipal UserAccount currentUser,
                                                  @RequestParam String title,
                                                  @RequestParam(defaultValue = "IMAGE") MediaType mediaType,
                                                  @RequestParam(required = false) Long productId,
                                                  @RequestParam(required = false) String description,
                                                  @RequestParam MultipartFile file,
                                                  @RequestParam(required = false) MultipartFile coverFile) {
        requireMediaManager(currentUser);
        return ApiResponse.ok(
                mediaAssetService.upload(title, mediaType, productId, description, file, coverFile, currentUser.getId()),
                "media uploaded"
        );
    }

    @PutMapping("/{id}")
    public ApiResponse<MediaAssetResponse> update(@AuthenticationPrincipal UserAccount currentUser,
                                                  @PathVariable Long id,
                                                  @Valid @RequestBody UpsertMediaAssetRequest request) {
        requireMediaManager(currentUser);
        return ApiResponse.ok(mediaAssetService.update(id, request), "media updated");
    }

    @PutMapping("/{id}/audit")
    public ApiResponse<MediaAssetResponse> audit(@AuthenticationPrincipal UserAccount currentUser,
                                                 @PathVariable Long id,
                                                 @Valid @RequestBody MediaAuditRequest request) {
        requireMediaManager(currentUser);
        return ApiResponse.ok(mediaAssetService.audit(id, request.approved(), request.remark(), currentUser.getId()), "media audited");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        requireMediaManager(currentUser);
        mediaAssetService.delete(id);
        return ApiResponse.ok(null, "media deleted");
    }

    private void requireMediaManager(UserAccount user) {
        if (!isMediaManager(user)) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }

    private boolean isMediaManager(UserAccount user) {
        return user != null && (user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT);
    }
}
