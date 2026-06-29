package com.petemarket.server.behavior;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.order.OrderItem;
import com.petemarket.server.order.PetOrder;
import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserBehaviorService {
    private final UserBehaviorRepository userBehaviorRepository;
    private final ProductRepository productRepository;

    public UserBehaviorService(UserBehaviorRepository userBehaviorRepository, ProductRepository productRepository) {
        this.userBehaviorRepository = userBehaviorRepository;
        this.productRepository = productRepository;
    }

    @Transactional(readOnly = true)
    public List<UserBehaviorResponse> list(UserAccount currentUser) {
        List<UserBehavior> behaviors = isAdminOrMerchant(currentUser)
                ? userBehaviorRepository.findAllByOrderByCreatedAtDesc()
                : userBehaviorRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId());
        return behaviors.stream().map(UserBehaviorResponse::from).toList();
    }

    @Transactional
    public UserBehaviorResponse track(UserAccount currentUser, TrackBehaviorRequest request) {
        Product product = findProduct(request.productId());
        return UserBehaviorResponse.from(record(
                currentUser.getId(),
                product,
                request.behaviorType(),
                request.scene(),
                request.quantity()
        ));
    }

    @Transactional
    public void record(Long userId, Long productId, UserBehaviorType type, String scene, Integer quantity) {
        record(userId, findProduct(productId), type, scene, quantity);
    }

    @Transactional
    public void recordOrderItems(PetOrder order, UserBehaviorType type, String scene) {
        for (OrderItem item : order.getItems()) {
            productRepository.findById(item.getProductId()).ifPresent(product ->
                    record(order.getUserId(), product, type, scene, item.getQuantity())
            );
        }
    }

    private UserBehavior record(Long userId,
                                Product product,
                                UserBehaviorType type,
                                String scene,
                                Integer quantity) {
        UserBehavior behavior = new UserBehavior();
        behavior.setUserId(userId);
        behavior.setProductId(product.getId());
        behavior.setProductName(product.getName());
        behavior.setCategory(defaultText(product.getCategory(), "General"));
        behavior.setProductType(product.getType().name());
        behavior.setStoreId(product.getStoreId());
        behavior.setBehaviorType(type);
        behavior.setQuantity(Math.max(1, quantity == null ? 1 : quantity));
        behavior.setWeight(type.weight() * behavior.getQuantity());
        behavior.setScene(defaultText(scene, "APP"));
        return userBehaviorRepository.save(behavior);
    }

    private Product findProduct(Long productId) {
        return productRepository.findById(productId)
                .orElseThrow(() -> new BusinessException("200404", "Product not found", HttpStatus.NOT_FOUND));
    }

    private boolean isAdminOrMerchant(UserAccount user) {
        return user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT;
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
