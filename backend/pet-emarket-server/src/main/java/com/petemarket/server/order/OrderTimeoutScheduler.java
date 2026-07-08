package com.petemarket.server.order;

import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@EnableScheduling
public class OrderTimeoutScheduler {
    private static final Logger log = LoggerFactory.getLogger(OrderTimeoutScheduler.class);
    private final OrderRepository orderRepository;

    public OrderTimeoutScheduler(OrderRepository orderRepository) { this.orderRepository = orderRepository; }

    @Scheduled(fixedRate = 30000) // 每30秒检查一次
    @Transactional
    public void cancelExpiredOrders() {
        List<PetOrder> expired = orderRepository.findByStatusAndPaymentDeadlineBefore(
                OrderStatus.WAIT_PAY.code(), Instant.now());
        for (PetOrder order : expired) {
            order.setStatus(OrderStatus.CANCELED.code());
            order.setAuditRemark("支付超时自动取消");
            log.info("Order {} auto-cancelled due to payment timeout", order.getOrderNo());
        }
        if (!expired.isEmpty()) {
            orderRepository.saveAll(expired);
        }
    }
}
