package com.petemarket.server.announcement;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/announcements")
public class AnnouncementController {
    private final AnnouncementService service;

    public AnnouncementController(AnnouncementService service) { this.service = service; }

    /** 用户端：获取已发布公告（无需登录） */
    @GetMapping
    public ApiResponse<List<Map<String, Object>>> list(@AuthenticationPrincipal UserAccount u) {
        // u 可能为 null，不强制校验登录态
        return ApiResponse.ok(service.listPublished().stream().map(this::toMap).toList());
    }

    /** 管理端：获取全部公告（含草稿） */
    @GetMapping("/all")
    public ApiResponse<List<Map<String, Object>>> listAll(@AuthenticationPrincipal UserAccount u) {
        requireAdmin(u);
        return ApiResponse.ok(service.listAll().stream().map(this::toMap).toList());
    }

    /** 管理端：创建 */
    @PostMapping
    public ApiResponse<Map<String, Object>> create(@AuthenticationPrincipal UserAccount u, @RequestBody Map<String, Object> body) {
        requireAdmin(u);
        String title = body.get("title") != null ? body.get("title").toString() : "";
        String content = body.get("content") != null ? body.get("content").toString() : "";
        Long targetUserId = body.get("targetUserId") != null ? Long.valueOf(body.get("targetUserId").toString()) : null;
        return ApiResponse.ok(toMap(service.create(title, content, u.getId(), targetUserId)));
    }

    /** 管理端：更新 */
    @PutMapping("/{id}")
    public ApiResponse<Map<String, Object>> update(@AuthenticationPrincipal UserAccount u, @PathVariable Long id, @RequestBody Map<String, Object> body) {
        requireAdmin(u);
        String title = body.get("title") != null ? body.get("title").toString() : null;
        String content = body.get("content") != null ? body.get("content").toString() : null;
        Boolean published = body.containsKey("published") ? Boolean.valueOf(body.get("published").toString()) : null;
        Long targetUserId = body.get("targetUserId") != null ? Long.valueOf(body.get("targetUserId").toString()) : null;
        return ApiResponse.ok(toMap(service.update(id, title, content, published, targetUserId)));
    }

    /** 管理端：删除 */
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount u, @PathVariable Long id) {
        requireAdmin(u); service.delete(id);
        return ApiResponse.ok(null, "deleted");
    }

    private Map<String, Object> toMap(Announcement a) {
        Map<String, Object> map = new java.util.LinkedHashMap<>();
        map.put("id", a.getId());
        map.put("title", a.getTitle() != null ? a.getTitle() : "");
        map.put("content", a.getContent() != null ? a.getContent() : "");
        map.put("published", a.getPublished() != null && a.getPublished());
        map.put("targetUserId", a.getTargetUserId());
        map.put("createdAt", a.getCreatedAt() != null ? a.getCreatedAt().toString() : "");
        map.put("updatedAt", a.getUpdatedAt() != null ? a.getUpdatedAt().toString() : "");
        return map;
    }

    private void requireAdmin(UserAccount u) {
        if (u == null || u.getRole() != UserRole.ADMIN) throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
    }
}
