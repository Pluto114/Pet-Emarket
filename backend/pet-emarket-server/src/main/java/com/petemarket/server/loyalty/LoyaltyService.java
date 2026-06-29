package com.petemarket.server.loyalty;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.order.PetOrder;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRepository;
import com.petemarket.server.user.UserRole;
import java.math.RoundingMode;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LoyaltyService {
    private final PointLedgerRepository pointLedgerRepository;
    private final UserRepository userRepository;

    public LoyaltyService(PointLedgerRepository pointLedgerRepository, UserRepository userRepository) {
        this.pointLedgerRepository = pointLedgerRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<PointLedgerResponse> list(UserAccount currentUser) {
        List<PointLedger> ledgers = isAdminOrMerchant(currentUser)
                ? pointLedgerRepository.findAllByOrderByCreatedAtDesc()
                : pointLedgerRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId());
        return ledgers.stream().map(PointLedgerResponse::from).toList();
    }

    public void awardOrderPoints(PetOrder order) {
        pointLedgerRepository.findByOrderIdAndType(order.getId(), PointLedgerType.EARN_ORDER)
                .ifPresentOrElse(ledger -> {
                    order.setRewardPoints(ledger.getPoints());
                    order.setPointsReversed(false);
                }, () -> createEarnLedger(order));
    }

    public void reverseOrderPoints(PetOrder order, String remark) {
        if (Boolean.TRUE.equals(order.getPointsReversed())) {
            return;
        }
        pointLedgerRepository.findByOrderIdAndType(order.getId(), PointLedgerType.EARN_ORDER)
                .ifPresent(earned -> pointLedgerRepository.findByOrderIdAndType(order.getId(), PointLedgerType.REFUND_REVERSE)
                        .ifPresentOrElse(ignored -> order.setPointsReversed(true), () -> createReverseLedger(order, earned, remark)));
    }

    private void createEarnLedger(PetOrder order) {
        int points = order.getPayAmount().setScale(0, RoundingMode.DOWN).intValue();
        if (points <= 0) {
            return;
        }
        UserAccount user = findUser(order.getUserId());
        int balance = safeBalance(user) + points;
        user.setPointsBalance(balance);
        order.setRewardPoints(points);
        order.setPointsReversed(false);
        pointLedgerRepository.save(ledger(order, PointLedgerType.EARN_ORDER, points, balance, "Order payment reward"));
    }

    private void createReverseLedger(PetOrder order, PointLedger earned, String remark) {
        UserAccount user = findUser(order.getUserId());
        int reversePoints = -Math.max(0, earned.getPoints());
        int balance = Math.max(0, safeBalance(user) + reversePoints);
        user.setPointsBalance(balance);
        order.setPointsReversed(true);
        pointLedgerRepository.save(ledger(order, PointLedgerType.REFUND_REVERSE, reversePoints, balance, remark));
    }

    private PointLedger ledger(PetOrder order,
                               PointLedgerType type,
                               int points,
                               int balanceAfter,
                               String remark) {
        PointLedger ledger = new PointLedger();
        ledger.setUserId(order.getUserId());
        ledger.setOrderId(order.getId());
        ledger.setOrderNo(order.getOrderNo());
        ledger.setType(type);
        ledger.setPoints(points);
        ledger.setBalanceAfter(balanceAfter);
        ledger.setRemark(remark);
        return ledger;
    }

    private UserAccount findUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("100404", "User not found", HttpStatus.NOT_FOUND));
    }

    private int safeBalance(UserAccount user) {
        return user.getPointsBalance() == null ? 0 : user.getPointsBalance();
    }

    private boolean isAdminOrMerchant(UserAccount user) {
        return user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT;
    }
}
