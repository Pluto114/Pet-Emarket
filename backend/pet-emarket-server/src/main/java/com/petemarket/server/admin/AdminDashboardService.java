package com.petemarket.server.admin;

import com.petemarket.server.order.OrderItem;
import com.petemarket.server.order.OrderRepository;
import com.petemarket.server.order.OrderStatus;
import com.petemarket.server.order.PetOrder;
import com.petemarket.server.product.ProductAuditStatus;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductStatus;
import com.petemarket.server.product.ProductType;
import com.petemarket.server.store.PetStoreRepository;
import com.petemarket.server.store.StoreStatus;
import com.petemarket.server.user.AccountStatus;
import com.petemarket.server.user.UserRepository;
import com.petemarket.server.user.UserRole;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminDashboardService {
    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final PetStoreRepository storeRepository;
    private final OrderRepository orderRepository;

    public AdminDashboardService(UserRepository userRepository,
                                 ProductRepository productRepository,
                                 PetStoreRepository storeRepository,
                                 OrderRepository orderRepository) {
        this.userRepository = userRepository;
        this.productRepository = productRepository;
        this.storeRepository = storeRepository;
        this.orderRepository = orderRepository;
    }

    @Transactional(readOnly = true)
    public AdminDashboardResponse dashboard() {
        List<PetOrder> orders = orderRepository.findAllByOrderByCreatedAtDesc();
        Map<Integer, Long> statusCounts = new LinkedHashMap<>();
        BigDecimal totalPayAmount = BigDecimal.ZERO;
        Map<Long, ProductAccumulator> productRank = new LinkedHashMap<>();

        for (PetOrder order : orders) {
            statusCounts.merge(order.getStatus(), 1L, Long::sum);
            if (order.getStatus() != OrderStatus.CANCELED.code()
                    && order.getStatus() != OrderStatus.REFUND_SUCCESS.code()
                    && order.getStatus() != OrderStatus.ADMIN_REFUND.code()) {
                totalPayAmount = totalPayAmount.add(order.getPayAmount());
            }
            for (OrderItem item : order.getItems()) {
                if (item.getProductId() == null) {
                    continue;
                }
                productRank.computeIfAbsent(item.getProductId(), ignored -> new ProductAccumulator(
                        item.getProductId(),
                        item.getProductName(),
                        item.getCategory()
                )).add(item);
            }
        }

        List<OrderStatusCountResponse> distribution = statusCounts.entrySet().stream()
                .map(entry -> new OrderStatusCountResponse(
                        entry.getKey(),
                        OrderStatus.fromCode(entry.getKey()).label(),
                        entry.getValue()
                ))
                .toList();
        List<TopProductResponse> topProducts = productRank.values().stream()
                .sorted(Comparator.comparing(ProductAccumulator::quantity).reversed()
                        .thenComparing(ProductAccumulator::amount).reversed())
                .limit(5)
                .map(ProductAccumulator::toResponse)
                .toList();
        List<RecentOrderResponse> recentOrders = orders.stream()
                .limit(5)
                .map(order -> new RecentOrderResponse(
                        order.getId(),
                        order.getOrderNo(),
                        order.getUserId(),
                        order.getStatus(),
                        order.getStatusName(),
                        order.getPayAmount(),
                        order.getCreatedAt()
                ))
                .toList();

        return new AdminDashboardResponse(
                userRepository.count(),
                userRepository.countByStatus(AccountStatus.ACTIVE),
                userRepository.countByRole(UserRole.MERCHANT),
                productRepository.count(),
                productRepository.countByStatus(ProductStatus.ON_SALE),
                productRepository.countByType(ProductType.PET_LIVE),
                productRepository.countByTypeAndAuditStatus(ProductType.PET_LIVE, ProductAuditStatus.PENDING),
                storeRepository.count(),
                storeRepository.countByStatus(StoreStatus.OPEN),
                orders.size(),
                statusCounts.getOrDefault(OrderStatus.REFUND_APPLIED.code(), 0L),
                totalPayAmount,
                distribution,
                topProducts,
                recentOrders,
                Instant.now()
        );
    }

    private static final class ProductAccumulator {
        private final Long productId;
        private final String productName;
        private final String category;
        private long quantity;
        private BigDecimal amount = BigDecimal.ZERO;

        private ProductAccumulator(Long productId, String productName, String category) {
            this.productId = productId;
            this.productName = productName;
            this.category = category;
        }

        private void add(OrderItem item) {
            long itemQuantity = item.getQuantity() == null ? 1 : item.getQuantity();
            quantity += itemQuantity;
            amount = amount.add(item.getSubtotal() == null ? BigDecimal.ZERO : item.getSubtotal());
        }

        private long quantity() {
            return quantity;
        }

        private BigDecimal amount() {
            return amount;
        }

        private TopProductResponse toResponse() {
            return new TopProductResponse(productId, productName, category, quantity, amount);
        }
    }
}
