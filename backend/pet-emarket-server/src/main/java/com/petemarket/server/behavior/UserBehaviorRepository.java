package com.petemarket.server.behavior;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserBehaviorRepository extends JpaRepository<UserBehavior, Long> {
    List<UserBehavior> findAllByOrderByCreatedAtDesc();

    List<UserBehavior> findByUserIdOrderByCreatedAtDesc(Long userId);
}
