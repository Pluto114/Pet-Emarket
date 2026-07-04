package com.petemarket.server.order;

import com.petemarket.server.address.ShippingAddressService;
import com.petemarket.server.cart.CartItem;
import com.petemarket.server.cart.CartItemRepository;
import com.petemarket.server.behavior.UserBehaviorService;
import com.petemarket.server.behavior.UserBehaviorType;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.loyalty.LoyaltyService;
import com.petemarket.server.payment.PaymentRecord;
import com.petemarket.server.payment.PaymentService;
import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductStatus;
import com.petemarket.server.product.ProductType;
import com.petemarket.server.store.StoreService;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {
    private static final Logger log = LoggerFactory.getLogger(OrderService.class);
    private static final long PAYMENT_TIMEOUT_MINUTES = 30;

    private final OrderRepository orderRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final PaymentService paymentService;
    private final LoyaltyService loyaltyService;
    private final UserBehaviorService userBehaviorService;
    private final ShippingAddressService shippingAddressService;
    private final StoreService storeService;
    private ScheduledExecutorService scheduler;
    private final Map<Long, ScheduledFuture<?>> paymentTimeouts = new ConcurrentHashMap<>();

    public OrderService(OrderRepository orderRepository,
                        CartItemRepository cartItemRepository,
                        ProductRepository productRepository,
                        PaymentService paymentService,
                        LoyaltyService loyaltyService,
                        UserBehaviorService userBehaviorService,
                        ShippingAddressService shippingAddressService,
                        StoreService storeService) {
        this.orderRepository = orderRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.paymentService = paymentService;
        this.loyaltyService = loyaltyService;
        this.userBehaviorService = userBehaviorService;
        this.shippingAddressService = shippingAddressService;
        this.storeService = storeService;
    }

    @PostConstruct
    public void init() {
        scheduler = Executors.newScheduledThreadPool(1, r -> {
            Thread t = new Thread(r, "order-payment-timeout");
            t.setDaemon(true);
            return t;
        });
    }

    @PreDestroy
    public void destroy() {
        if (scheduler != null) scheduler.shutdownNow();
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> list(UserAccount currentUser) {
        List<PetOrder> orders = currentUser.getRole() == UserRole.ADMIN
                ? orderRepository.findAllByOrderByCreatedAtDesc()
                : currentUser.getRole() == UserRole.MERCHANT
                        ? merchantOrders(currentUser)
                        : orderRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId());
        return orders.stream().map(OrderResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public OrderResponse get(UserAccount currentUser, Long id) {
        PetOrder order = findAndAuthorize(currentUser, id);
        return OrderResponse.from(order);
    }

    @Transactional
    public OrderResponse create(UserAccount currentUser, CreateOrderRequest request) {
        List<CartItem> cartItems = cartItemRepository.findByUserId(currentUser.getId());
        if (request.cartItemIds() != null && !request.cartItemIds().isEmpty()) {
            cartItems = cartItems.stream().filter(item -> request.cartItemIds().contains(item.getId())).toList();
        }
        if (cartItems.isEmpty()) {
            throw new BusinessException("300400", "Cart is empty");
        }

        PetOrder order = new PetOrder();
        order.setOrderNo("PE" + Instant.now().toEpochMilli());
        order.setUserId(currentUser.getId());
        AddressSnapshot address = resolveAddress(currentUser, request);
        order.setReceiver(address.receiver());
        order.setPhone(address.phone());
        order.setAddressDetail(address.detail());

        BigDecimal total = BigDecimal.ZERO;
        for (CartItem cartItem : cartItems) {
            Product product = productRepository.findById(cartItem.getProductId())
                    .orElseThrow(() -> new BusinessException("200404", "Product not found", HttpStatus.NOT_FOUND));
            if (product.getStatus() != ProductStatus.ON_SALE) {
                throw new BusinessException("200409", product.getName() + " is not on sale");
            }
            if (product.getStock() < cartItem.getQuantity()) {
                throw new BusinessException("300409", "Insufficient stock for " + product.getName());
            }
            product.setStock(product.getStock() - cartItem.getQuantity());
            if (product.getStock() <= 0) {
                product.setStatus(ProductStatus.OFF_SALE);
            }
            BigDecimal subtotal = product.getPrice().multiply(BigDecimal.valueOf(cartItem.getQuantity()));
            total = total.add(subtotal);
            order.addItem(snapshotItem(product, cartItem.getQuantity(), subtotal));
        }
        BigDecimal discount = total.multiply(currentUser.getMemberLevel().discountRate()).setScale(2, RoundingMode.HALF_UP);
        order.setTotalAmount(total.setScale(2, RoundingMode.HALF_UP));
        order.setDiscountAmount(discount);
        order.setPayAmount(total.subtract(discount).setScale(2, RoundingMode.HALF_UP));
        appendLog(order, null, OrderStatus.WAIT_PAY.code(), currentUser, "创建订单");
        orderRepository.save(order);
        userBehaviorService.recordOrderItems(order, UserBehaviorType.PURCHASE, "ORDER_CREATE");
        cartItemRepository.deleteAll(cartItems);
        schedulePaymentTimeout(order);
        return OrderResponse.from(order);
    }

    private void schedulePaymentTimeout(PetOrder order) {
        ScheduledFuture<?> future = scheduler.schedule(() -> {
            try {
                cancelUnpaidOrder(order.getId());
            } catch (Exception e) {
                log.error("Failed to auto-cancel unpaid order {}", order.getId(), e);
            }
        }, PAYMENT_TIMEOUT_MINUTES, TimeUnit.MINUTES);
        paymentTimeouts.put(order.getId(), future);
        log.info("Order {} payment timeout scheduled in {} minutes", order.getOrderNo(), PAYMENT_TIMEOUT_MINUTES);
    }

    @Transactional
    public void cancelUnpaidOrder(Long orderId) {
        PetOrder order = orderRepository.findById(orderId).orElse(null);
        if (order == null) return;
        if (order.getStatus() != OrderStatus.WAIT_PAY.code()) {
            paymentTimeouts.remove(orderId);
            return;
        }
        log.info("Auto-cancelling unpaid order {} (timeout)", order.getOrderNo());
        order.setStatus(OrderStatus.CANCELED.code());
        appendLog(order, OrderStatus.WAIT_PAY.code(), OrderStatus.CANCELED.code(), null, "超时未支付，系统自动取消");
        restoreInventory(order);
        orderRepository.save(order);
        paymentTimeouts.remove(orderId);
    }

    private AddressSnapshot resolveAddress(UserAccount currentUser, CreateOrderRequest request) {
        if (request.addressId() != null) {
            return shippingAddressService.snapshot(currentUser.getId(), request.addressId());
        }
        if (request.addressSnapshot() != null) {
            return request.addressSnapshot();
        }
        AddressSnapshot defaultAddress = shippingAddressService.defaultSnapshot(currentUser.getId());
        if (defaultAddress == null) {
            throw new BusinessException("300400", "请先选择或新增真实收货地址");
        }
        return defaultAddress;
    }

    @Transactional
    public OrderResponse operate(UserAccount currentUser, Long id, String action, OrderActionRequest request) {
        PetOrder order = findAndAuthorize(currentUser, id);
        switch (action) {
            case "pay" -> {
                transition(order, currentUser, List.of(0), 1, "支付成功");
                PaymentRecord payment = paymentService.recordPayment(order);
                order.setPaymentNo(payment.getPaymentNo());
                order.setPaidAt(payment.getPaidAt());
                loyaltyService.awardOrderPoints(order);
                cancelPaymentTimeout(order.getId());
            }
            case "ship" -> {
                requireAdminOrMerchant(currentUser);
                transition(order, currentUser, List.of(1), 2, "管理员发货");
            }
            case "receive" -> transition(order, currentUser, List.of(2), 3, "用户确认收货");
            case "review" -> {
                validateRating(request.rating());
                transition(order, currentUser, List.of(3), 4, "用户评价完成");
                order.setReviewRating(request.rating() == null ? 5 : request.rating());
                order.setReviewContent(defaultText(request.content(), "默认好评"));
                userBehaviorService.recordOrderItems(order, UserBehaviorType.REVIEW, "ORDER_REVIEW");
            }
            case "cancel" -> {
                boolean paidCancel = order.getStatus() == OrderStatus.WAIT_SHIP.code();
                transition(order, currentUser, List.of(0, 1), -1, defaultText(request.reason(), "取消订单"));
                cancelPaymentTimeout(order.getId());
                restoreInventory(order);
                if (paidCancel) {
                    refundPaymentAndReversePoints(order, defaultText(request.reason(), "取消订单退款"));
                }
            }
            case "apply-refund" -> {
                int rollbackStatus = order.getStatus();
                transition(order, currentUser, List.of(2, 3), -2, defaultText(request.reason(), "用户申请退单"));
                order.setRefundReason(defaultText(request.reason(), "用户申请退单"));
                order.setRefundAuditStatus("PENDING");
                order.setRefundRollbackStatus(rollbackStatus);
            }
            case "audit-refund" -> {
                requireAdminOrMerchant(currentUser);
                if (order.getStatus() != -2) {
                    throw new BusinessException("300409", "Only refund requests can be audited");
                }
                boolean approved = Boolean.TRUE.equals(request.approved());
                // 商家驳回 → 升级交给管理员最终裁定
                if (!approved && currentUser.getRole() == UserRole.MERCHANT) {
                    transition(order, currentUser, List.of(-2), -2, "商家驳回退单，升级至管理员裁定");
                    order.setRefundAuditStatus("ESCALATED_TO_ADMIN");
                    order.setAuditRemark(defaultText(request.auditRemark(), "商家驳回，升级管理员"));
                } else {
                    int target = approved ? -3 : resolveRefundRollbackStatus(order, request.rollbackStatus());
                    transition(order, currentUser, List.of(-2), target, approved ? "退单审核通过" : "退单审核不通过");
                    order.setRefundAuditStatus(approved ? "APPROVED" : "REJECTED");
                    order.setAuditRemark(defaultText(request.auditRemark(), ""));
                    if (approved) {
                        restoreInventory(order);
                        refundPaymentAndReversePoints(order, defaultText(request.auditRemark(), "退单审核通过"));
                    }
                }
            }
            case "escalate-refund" -> {
                // 商家主动升级给管理员
                if (currentUser.getRole() != UserRole.MERCHANT) {
                    throw new BusinessException("100403", "Only merchants can escalate refund", HttpStatus.FORBIDDEN);
                }
                if (order.getStatus() != -2) {
                    throw new BusinessException("300409", "Only pending refund requests can be escalated");
                }
                transition(order, currentUser, List.of(-2), -2, "商家升级退单至管理员裁定");
                order.setRefundAuditStatus("ESCALATED_TO_ADMIN");
                order.setAuditRemark(defaultText(request.auditRemark(), "商家主动升级"));
            }
            case "admin-refund" -> {
                requireAdminOrMerchant(currentUser);
                transition(order, currentUser, List.of(3, 4), -4, defaultText(request.reason(), "管理员直接退单"));
                order.setRefundReason(defaultText(request.reason(), "管理员直接退单"));
                order.setRefundAuditStatus("DIRECT_REFUND");
                restoreInventory(order);
                refundPaymentAndReversePoints(order, defaultText(request.reason(), "管理员直接退单"));
            }
            default -> throw new BusinessException("300400", "Unknown order action");
        }
        return OrderResponse.from(order);
    }

    private OrderItem snapshotItem(Product product, Integer quantity, BigDecimal subtotal) {
        OrderItem item = new OrderItem();
        item.setProductId(product.getId());
        item.setStoreId(product.getStoreId());
        item.setProductName(product.getName());
        item.setProductType(product.getType().name());
        item.setCategory(product.getCategory());
        item.setUnitPrice(product.getPrice());
        item.setQuantity(quantity);
        item.setSubtotal(subtotal.setScale(2, RoundingMode.HALF_UP));
        if (product.getType() == ProductType.PET_LIVE) {
            item.setLivePetSnapshot("petCode=" + product.getPetCode()
                    + ", vaccineCertNo=" + product.getVaccineCertNo()
                    + ", quarantineCertNo=" + product.getQuarantineCertNo()
                    + ", healthStatus=" + product.getHealthStatus());
        }
        return item;
    }

    private void transition(PetOrder order, UserAccount actor, List<Integer> from, int to, String reason) {
        if (!from.contains(order.getStatus())) {
            throw new BusinessException("300409", "Cannot transition order from status " + order.getStatus());
        }
        Integer oldStatus = order.getStatus();
        order.setStatus(to);
        appendLog(order, oldStatus, to, actor, reason);
    }

    private void appendLog(PetOrder order, Integer from, Integer to, UserAccount actor, String reason) {
        OrderStatusLog log = new OrderStatusLog();
        log.setFromStatus(from);
        log.setToStatus(to);
        log.setOperatorRole(actor != null ? actor.getRole().name() : "SYSTEM");
        log.setReason(reason);
        order.addStatusLog(log);
    }

    private void cancelPaymentTimeout(Long orderId) {
        ScheduledFuture<?> future = paymentTimeouts.remove(orderId);
        if (future != null) future.cancel(false);
    }

    private void restoreInventory(PetOrder order) {
        if (Boolean.TRUE.equals(order.getInventoryRestored())) {
            return;
        }
        for (OrderItem item : order.getItems()) {
            int quantity = Math.max(0, item.getQuantity() == null ? 0 : item.getQuantity());
            if (quantity == 0) {
                continue;
            }
            productRepository.findById(item.getProductId()).ifPresent(product -> {
                int currentStock = Math.max(0, product.getStock() == null ? 0 : product.getStock());
                product.setStock(currentStock + quantity);
            });
        }
        order.setInventoryRestored(true);
    }

    private void refundPaymentAndReversePoints(PetOrder order, String reason) {
        paymentService.recordRefund(order, reason);
        loyaltyService.reverseOrderPoints(order, reason);
    }

    private int resolveRefundRollbackStatus(PetOrder order, Integer requestedStatus) {
        int target = requestedStatus == null
                ? (order.getRefundRollbackStatus() == null ? OrderStatus.WAIT_RECEIVE.code() : order.getRefundRollbackStatus())
                : requestedStatus;
        if (target != OrderStatus.WAIT_RECEIVE.code() && target != OrderStatus.WAIT_REVIEW.code()) {
            throw new BusinessException("300400", "Refund rejection can only rollback to receive or review status");
        }
        return target;
    }

    private void validateRating(Integer rating) {
        if (rating != null && (rating < 1 || rating > 5)) {
            throw new BusinessException("300400", "Review rating must be between 1 and 5");
        }
    }

    private PetOrder findAndAuthorize(UserAccount user, Long id) {
        PetOrder order = orderRepository.findById(id)
                .orElseThrow(() -> new BusinessException("300404", "Order not found", HttpStatus.NOT_FOUND));
        if (user.getRole() == UserRole.ADMIN) {
            return order;
        }
        if (user.getRole() == UserRole.MERCHANT && orderContainsManagedStore(user, order)) {
            return order;
        }
        if (!order.getUserId().equals(user.getId())) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
        return order;
    }

    private boolean isAdminOrMerchant(UserAccount user) {
        return user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT;
    }

    private List<PetOrder> merchantOrders(UserAccount user) {
        return orderRepository.findAllByOrderByCreatedAtDesc().stream()
                .filter(order -> orderContainsManagedStore(user, order))
                .toList();
    }

    private boolean orderContainsManagedStore(UserAccount user, PetOrder order) {
        List<Long> storeIds = storeService.managedStoreIds(user);
        if (storeIds.isEmpty()) {
            return false;
        }
        return order.getItems().stream()
                .map(OrderItem::getStoreId)
                .anyMatch(storeIds::contains);
    }

    private void requireAdminOrMerchant(UserAccount user) {
        if (!isAdminOrMerchant(user)) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
