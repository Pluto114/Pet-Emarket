package com.petemarket.server.cart;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductStatus;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CartService {
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;

    public CartService(CartItemRepository cartItemRepository, ProductRepository productRepository) {
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
    }

    @Transactional(readOnly = true)
    public List<CartItemResponse> list(Long userId) {
        return cartItemRepository.findByUserId(userId).stream().map(this::toResponse).toList();
    }

    @Transactional
    public CartItemResponse add(Long userId, AddCartItemRequest request) {
        Product product = findProduct(request.productId());
        requireAvailable(product);
        int quantity = sanitizeQuantity(request.quantity());
        if (product.getStock() < quantity) {
            throw new BusinessException("300409", "Insufficient stock");
        }
        CartItem item = cartItemRepository.findByUserIdAndProductId(userId, product.getId()).orElseGet(CartItem::new);
        int mergedQuantity = (item.getQuantity() == null ? 0 : item.getQuantity()) + quantity;
        if (product.getStock() < mergedQuantity) {
            throw new BusinessException("300409", "Insufficient stock");
        }
        item.setUserId(userId);
        item.setProductId(product.getId());
        item.setQuantity(mergedQuantity);
        cartItemRepository.save(item);
        return CartItemResponse.from(item, product);
    }

    @Transactional
    public CartItemResponse update(Long userId, Long itemId, UpdateCartItemRequest request) {
        CartItem item = findOwned(itemId, userId);
        Product product = findProduct(item.getProductId());
        int quantity = sanitizeQuantity(request.quantity());
        if (product.getStock() < quantity) {
            throw new BusinessException("300409", "Insufficient stock");
        }
        item.setQuantity(quantity);
        return CartItemResponse.from(item, product);
    }

    @Transactional
    public void delete(Long userId, Long itemId) {
        cartItemRepository.delete(findOwned(itemId, userId));
    }

    private CartItemResponse toResponse(CartItem item) {
        return CartItemResponse.from(item, findProduct(item.getProductId()));
    }

    private CartItem findOwned(Long itemId, Long userId) {
        return cartItemRepository.findByIdAndUserId(itemId, userId)
                .orElseThrow(() -> new BusinessException("300404", "Cart item not found", HttpStatus.NOT_FOUND));
    }

    private Product findProduct(Long productId) {
        return productRepository.findById(productId)
                .orElseThrow(() -> new BusinessException("200404", "Product not found", HttpStatus.NOT_FOUND));
    }

    private void requireAvailable(Product product) {
        if (product.getStatus() != ProductStatus.ON_SALE) {
            throw new BusinessException("200409", "Product is not on sale");
        }
    }

    private int sanitizeQuantity(Integer quantity) {
        return Math.max(1, quantity == null ? 1 : quantity);
    }
}
