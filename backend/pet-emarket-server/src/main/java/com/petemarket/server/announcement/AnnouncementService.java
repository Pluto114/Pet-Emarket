package com.petemarket.server.announcement;

import com.petemarket.server.common.BusinessException;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AnnouncementService {
    private final AnnouncementRepository repo;

    public AnnouncementService(AnnouncementRepository repo) { this.repo = repo; }

    /** 用户端：只看已发布的 */
    @Transactional(readOnly = true)
    public List<Announcement> listPublished() {
        return repo.findByPublishedTrueOrderByCreatedAtDesc();
    }

    /** 管理端：看全部 */
    @Transactional(readOnly = true)
    public List<Announcement> listAll() {
        return repo.findAllByOrderByCreatedAtDesc();
    }

    @Transactional
    public Announcement create(String title, String content, Long userId, Long targetUserId) {
        var a = new Announcement();
        a.setTitle(title); a.setContent(content); a.setCreatedBy(userId); a.setPublished(false);
        a.setTargetUserId(targetUserId);
        return repo.save(a);
    }

    @Transactional
    public Announcement update(Long id, String title, String content, Boolean published, Long targetUserId) {
        var a = repo.findById(id).orElseThrow(() -> new BusinessException("400404", "Announcement not found", HttpStatus.NOT_FOUND));
        if (title != null) a.setTitle(title);
        if (content != null) a.setContent(content);
        if (published != null) a.setPublished(published);
        if (targetUserId != null) a.setTargetUserId(targetUserId);
        return a;
    }

    @Transactional
    public void delete(Long id) {
        repo.deleteById(id);
    }
}
