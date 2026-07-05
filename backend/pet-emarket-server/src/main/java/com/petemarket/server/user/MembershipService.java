package com.petemarket.server.user;

import com.petemarket.server.order.PetOrder;
import java.math.BigDecimal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 会员等级自动升级服务
 *
 * 升级规则（基于累计消费金额）：
 *   NORMAL → VIP  ：累计消费 ≥ ¥500
 *   VIP    → SVIP ：累计消费 ≥ ¥2000
 *
 * 升级在支付成功后触发，只升不降。
 */
@Service
public class MembershipService {
    private static final Logger log = LoggerFactory.getLogger(MembershipService.class);

    private static final BigDecimal VIP_THRESHOLD = new BigDecimal("500");
    private static final BigDecimal SVIP_THRESHOLD = new BigDecimal("2000");

    private final UserRepository userRepository;

    public MembershipService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional
    public void recordSpendingAndUpgrade(PetOrder order) {
        UserAccount user = userRepository.findById(order.getUserId()).orElse(null);
        if (user == null) {
            log.warn("Membership upgrade skipped: user {} not found", order.getUserId());
            return;
        }
        BigDecimal currentTotal = user.getTotalSpent() != null ? user.getTotalSpent() : BigDecimal.ZERO;
        BigDecimal newTotal = currentTotal.add(order.getPayAmount());
        user.setTotalSpent(newTotal);

        MemberLevel oldLevel = user.getMemberLevel();
        MemberLevel newLevel = evaluateLevel(newTotal);

        if (newLevel.ordinal() > oldLevel.ordinal()) {
            user.setMemberLevel(newLevel);
            log.info("User {} ({}) upgraded: {} -> {} (total spent: {})",
                    user.getId(), user.getDisplayName(), oldLevel, newLevel, newTotal);
        }
        userRepository.save(user);
    }

    MemberLevel evaluateLevel(BigDecimal totalSpent) {
        if (totalSpent.compareTo(SVIP_THRESHOLD) >= 0) return MemberLevel.SVIP;
        if (totalSpent.compareTo(VIP_THRESHOLD) >= 0) return MemberLevel.VIP;
        return MemberLevel.NORMAL;
    }

    public BigDecimal amountToNextLevel(MemberLevel currentLevel, BigDecimal totalSpent) {
        return switch (currentLevel) {
            case NORMAL -> VIP_THRESHOLD.subtract(totalSpent).max(BigDecimal.ZERO);
            case VIP -> SVIP_THRESHOLD.subtract(totalSpent).max(BigDecimal.ZERO);
            case SVIP -> BigDecimal.ZERO;
        };
    }

    public BigDecimal getNextLevelThreshold(MemberLevel currentLevel) {
        return switch (currentLevel) {
            case NORMAL -> VIP_THRESHOLD;
            case VIP -> SVIP_THRESHOLD;
            case SVIP -> BigDecimal.ZERO;
        };
    }
}
