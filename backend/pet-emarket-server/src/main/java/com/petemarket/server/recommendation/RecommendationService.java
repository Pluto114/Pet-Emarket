package com.petemarket.server.recommendation;

import com.petemarket.server.order.OrderItem;
import com.petemarket.server.order.OrderRepository;
import com.petemarket.server.order.PetOrder;
import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductResponse;
import com.petemarket.server.product.ProductStatus;
import com.petemarket.server.store.PetStore;
import com.petemarket.server.store.PetStoreRepository;
import com.petemarket.server.store.StoreService;
import com.petemarket.server.user.UserAccount;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RecommendationService {
    private final ProductRepository productRepository;
    private final OrderRepository orderRepository;
    private final PetStoreRepository storeRepository;
    private final StoreService storeService;

    public RecommendationService(ProductRepository productRepository,
                                 OrderRepository orderRepository,
                                 PetStoreRepository storeRepository,
                                 StoreService storeService) {
        this.productRepository = productRepository;
        this.orderRepository = orderRepository;
        this.storeRepository = storeRepository;
        this.storeService = storeService;
    }

    @Transactional(readOnly = true)
    public List<RecommendationResponse> recommend(UserAccount currentUser,
                                                  String scene,
                                                  Long lastProductId,
                                                  Integer limit,
                                                  Double longitude,
                                                  Double latitude) {
        int pageSize = Math.min(Math.max(limit == null ? 8 : limit, 1), 20);
        String normalizedScene = scene == null || scene.isBlank()
                ? "HOME"
                : scene.trim().toUpperCase(Locale.ROOT);
        List<Product> candidates = productRepository.findByStatus(ProductStatus.ON_SALE).stream()
                .filter(product -> product.getStock() != null && product.getStock() > 0)
                .toList();
        if (candidates.isEmpty()) {
            return List.of();
        }

        List<PetOrder> orders = orderRepository.findAllByOrderByCreatedAtDesc();
        Map<Long, Product> productById = productRepository.findAll().stream()
                .collect(Collectors.toMap(Product::getId, Function.identity()));
        Map<Long, PetStore> storeById = storeRepository.findAll().stream()
                .collect(Collectors.toMap(PetStore::getId, Function.identity()));
        Map<String, Map<String, Double>> transitionMatrix = buildTransitionMatrix(orders);
        Map<String, Integer> categoryPreference = currentUser == null
                ? Map.of()
                : categoryPreference(currentUser.getId(), orders);
        Map<Long, Integer> hotCounts = hotCounts(orders);
        int maxHot = hotCounts.values().stream().max(Integer::compareTo).orElse(1);
        String currentState = resolveCurrentState(currentUser, lastProductId, orders, productById).orElse(null);

        return candidates.stream()
                .map(product -> scoreProduct(
                        product,
                        normalizedScene,
                        currentState,
                        transitionMatrix,
                        categoryPreference,
                        hotCounts,
                        maxHot,
                        storeById.get(product.getStoreId()),
                        longitude,
                        latitude
                ))
                .sorted(Comparator.comparingDouble(RecommendationResponse::score).reversed()
                        .thenComparing(response -> response.product().id()))
                .limit(pageSize)
                .toList();
    }

    private RecommendationResponse scoreProduct(Product product,
                                                String scene,
                                                String currentState,
                                                Map<String, Map<String, Double>> transitionMatrix,
                                                Map<String, Integer> categoryPreference,
                                                Map<Long, Integer> hotCounts,
                                                int maxHot,
                                                PetStore store,
                                                Double longitude,
                                                Double latitude) {
        List<String> reasons = new ArrayList<>();
        String category = product.getCategory();

        double itemCfScore = 0;
        int categoryWeight = categoryPreference.getOrDefault(category, 0);
        if (categoryWeight > 0) {
            itemCfScore = Math.min(25.0, 10.0 + categoryWeight * 5.0);
            reasons.add("协同过滤：匹配你的历史 " + category + " 偏好");
        }

        double markovScore = 0;
        if (currentState != null) {
            double transition = transitionMatrix.getOrDefault(currentState, Map.of()).getOrDefault(category, 0.0);
            if (transition > 0) {
                markovScore = transition * 35.0;
                reasons.add("马尔可夫链：从 " + currentState + " 转向 " + category + " 的概率较高");
            }
        }

        double hotScore = 0;
        int hotCount = hotCounts.getOrDefault(product.getId(), 0);
        if (hotCount > 0) {
            hotScore = hotCount * 15.0 / maxHot;
            reasons.add("热门商品：近期订单转化较好");
        }

        double distanceScore = 0;
        if (store != null && longitude != null && latitude != null) {
            double distanceKm = storeService.distanceToStoreKm(store, longitude, latitude);
            distanceScore = Math.max(0.0, 12.0 - distanceKm);
            if (distanceScore > 0) {
                reasons.add("附近门店：距离约 " + distanceKm + "km");
            }
        }

        double stockScore = product.getStock() >= 20 ? 8.0 : 4.0;
        reasons.add(product.getStock() >= 20 ? "库存充足" : "仍有库存，可尽快下单");

        double sceneWeight = "NEARBY".equals(scene) ? distanceScore * 0.35 : 0;
        double score = round(itemCfScore + markovScore + hotScore + distanceScore + stockScore + sceneWeight);

        if (reasons.size() == 1) {
            reasons.add("冷启动兜底：按上架状态、库存和门店评分推荐");
        }

        return new RecommendationResponse(
                ProductResponse.from(product),
                score,
                "HYBRID_ITEM_CF_MARKOV_HOT_LBS",
                reasons,
                round(itemCfScore),
                round(markovScore),
                round(hotScore),
                round(distanceScore),
                round(stockScore)
        );
    }

    private Map<String, Map<String, Double>> buildTransitionMatrix(List<PetOrder> orders) {
        Map<String, Map<String, Integer>> counts = new HashMap<>();
        Map<Long, List<String>> userSequences = new HashMap<>();

        orders.stream()
                .sorted(Comparator.comparing(PetOrder::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder())))
                .forEach(order -> {
                    List<String> sequence = userSequences.computeIfAbsent(order.getUserId(), ignored -> new ArrayList<>());
                    order.getItems().stream()
                            .map(OrderItem::getCategory)
                            .filter(Objects::nonNull)
                            .filter(category -> !category.isBlank())
                            .forEach(sequence::add);
                });

        for (List<String> sequence : userSequences.values()) {
            for (int i = 0; i < sequence.size() - 1; i++) {
                String from = sequence.get(i);
                String to = sequence.get(i + 1);
                counts.computeIfAbsent(from, ignored -> new HashMap<>())
                        .merge(to, 1, Integer::sum);
            }
        }

        Map<String, Map<String, Double>> matrix = new LinkedHashMap<>(defaultTransitionPriors());
        counts.forEach((from, toCounts) -> {
            int total = toCounts.values().stream().mapToInt(Integer::intValue).sum();
            Map<String, Double> normalized = new LinkedHashMap<>();
            toCounts.forEach((to, count) -> normalized.put(to, count * 1.0 / total));
            matrix.put(from, normalized);
        });
        return matrix;
    }

    private Map<String, Map<String, Double>> defaultTransitionPriors() {
        Map<String, Map<String, Double>> priors = new LinkedHashMap<>();
        priors.put("Cat", Map.of("Food", 0.48, "Care", 0.28, "Toy", 0.16));
        priors.put("Dog", Map.of("Food", 0.45, "Toy", 0.25, "Care", 0.20));
        priors.put("Food", Map.of("Care", 0.35, "Toy", 0.25, "Food", 0.20));
        priors.put("Care", Map.of("Food", 0.30, "Toy", 0.20));
        priors.put("Toy", Map.of("Food", 0.30, "Care", 0.18));
        return priors;
    }

    private Map<String, Integer> categoryPreference(Long userId, List<PetOrder> orders) {
        Map<String, Integer> preference = new HashMap<>();
        orders.stream()
                .filter(order -> Objects.equals(order.getUserId(), userId))
                .flatMap(order -> order.getItems().stream())
                .map(OrderItem::getCategory)
                .filter(Objects::nonNull)
                .filter(category -> !category.isBlank())
                .forEach(category -> preference.merge(category, 1, Integer::sum));
        return preference;
    }

    private Map<Long, Integer> hotCounts(List<PetOrder> orders) {
        Map<Long, Integer> counts = new HashMap<>();
        orders.stream()
                .flatMap(order -> order.getItems().stream())
                .filter(item -> item.getProductId() != null)
                .forEach(item -> counts.merge(item.getProductId(), Math.max(1, item.getQuantity() == null ? 1 : item.getQuantity()), Integer::sum));
        return counts;
    }

    private Optional<String> resolveCurrentState(UserAccount currentUser,
                                                 Long lastProductId,
                                                 List<PetOrder> orders,
                                                 Map<Long, Product> productById) {
        if (lastProductId != null && productById.containsKey(lastProductId)) {
            return Optional.ofNullable(productById.get(lastProductId).getCategory());
        }
        if (currentUser == null) {
            return Optional.empty();
        }
        return orders.stream()
                .filter(order -> Objects.equals(order.getUserId(), currentUser.getId()))
                .max(Comparator.comparing(PetOrder::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder())))
                .flatMap(order -> order.getItems().stream()
                        .map(OrderItem::getCategory)
                        .filter(Objects::nonNull)
                        .filter(category -> !category.isBlank())
                        .findFirst());
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
