package com.petemarket.server.order;

import com.petemarket.server.cart.CartItem;
import com.petemarket.server.cart.CartItemRepository;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductStatus;
import com.petemarket.server.product.ProductType;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;

    public OrderService(OrderRepository orderRepository,
                        CartItemRepository cartItemRepository,
                        ProductRepository productRepository) {
        this.orderRepository = orderRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
    }

    @Transactional(readOnly = true)
    public List<OrderResponse> list(UserAccount currentUser) {
        List<PetOrder> orders = isAdminOrMerchant(currentUser)
                ? orderRepository.findAllByOrderByCreatedAtDesc()
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
        AddressSnapshot address = request.addressSnapshot() == null
                ? new AddressSnapshot(currentUser.getDisplayName(), currentUser.getPhone(), "Pet-Emarket demo address")
                : request.addressSnapshot();
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
        cartItemRepository.deleteAll(cartItems);
        return OrderResponse.from(order);
    }

    @Transactional
    public OrderResponse operate(UserAccount currentUser, Long id, String action, OrderActionRequest request) {
        PetOrder order = findAndAuthorize(currentUser, id);
        switch (action) {
            case "pay" -> transition(order, currentUser, List.of(0), 1, "支付成功");
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
            }
            case "cancel" -> {
                transition(order, currentUser, List.of(0, 1), -1, defaultText(request.reason(), "取消订单"));
                restoreInventory(order);
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
                int target = approved ? -3 : resolveRefundRollbackStatus(order, request.rollbackStatus());
                transition(order, currentUser, List.of(-2), target, approved ? "退单审核通过" : "退单审核不通过");
                order.setRefundAuditStatus(approved ? "APPROVED" : "REJECTED");
                order.setAuditRemark(defaultText(request.auditRemark(), ""));
                if (approved) {
                    restoreInventory(order);
                }
            }
            case "admin-refund" -> {
                requireAdminOrMerchant(currentUser);
                transition(order, currentUser, List.of(3, 4), -4, defaultText(request.reason(), "管理员直接退单"));
                order.setRefundReason(defaultText(request.reason(), "管理员直接退单"));
                order.setRefundAuditStatus("DIRECT_REFUND");
                restoreInventory(order);
            }
            default -> throw new BusinessException("300400", "Unknown order action");
        }
        return OrderResponse.from(order);
    }

    private OrderItem snapshotItem(Product product, Integer quantity, BigDecimal subtotal) {
        OrderItem item = new OrderItem();
        item.setProductId(product.getId());
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
        log.setOperatorRole(actor.getRole().name());
        log.setReason(reason);
        order.addStatusLog(log);
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
        if (!isAdminOrMerchant(user) && !order.getUserId().equals(user.getId())) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
        return order;
    }

    private boolean isAdminOrMerchant(UserAccount user) {
        return user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT;
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
