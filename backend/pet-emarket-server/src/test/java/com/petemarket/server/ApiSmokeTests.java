package com.petemarket.server;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.JsonNode;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApiSmokeTests {
    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void publicHealthAndProductCatalogAreReadable() {
        ResponseEntity<JsonNode> health = restTemplate.getForEntity("/api/v1/health", JsonNode.class);

        assertThat(health.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(health).at("/data/status").asText()).isEqualTo("UP");
        assertThat(body(health).at("/data/service").asText()).isEqualTo("pet-emarket-server");

        ResponseEntity<JsonNode> products = restTemplate.getForEntity("/api/v1/products", JsonNode.class);

        assertThat(products.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(products).at("/data/items").isArray()).isTrue();
    }

    @Test
    void smartModulesExposeNearbyRecommendationAndAiApis() {
        ResponseEntity<JsonNode> nearby = restTemplate.getForEntity(
                "/api/v1/stores/nearby?longitude=120.1551&latitude=30.2741&radiusKm=30",
                JsonNode.class
        );

        assertThat(nearby.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(nearby).at("/data/items").size()).isGreaterThan(0);
        assertThat(body(nearby).at("/data/items/0/distanceKm").asDouble()).isGreaterThanOrEqualTo(0.0);

        ResponseEntity<JsonNode> products = restTemplate.getForEntity("/api/v1/products", JsonNode.class);
        long lastProductId = body(products).at("/data/items/0/id").asLong();
        ResponseEntity<JsonNode> recommendations = restTemplate.getForEntity(
                "/api/v1/recommendations?limit=5&lastProductId=" + lastProductId + "&longitude=120.1551&latitude=30.2741",
                JsonNode.class
        );

        assertThat(recommendations.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(recommendations).at("/data/items").size()).isGreaterThan(0);
        assertThat(body(recommendations).at("/data/items/0/score").asDouble()).isGreaterThan(0.0);
        assertThat(body(recommendations).at("/data/items/0/reasons").isArray()).isTrue();

        ResponseEntity<JsonNode> alias = restTemplate.getForEntity("/api/v1/recommend?limit=3", JsonNode.class);
        assertThat(alias.getStatusCode()).isEqualTo(HttpStatus.OK);

        ResponseEntity<JsonNode> chat = exchange(
                HttpMethod.POST,
                "/api/v1/ai/chat",
                Map.of("question", "猫咪拉稀怎么办", "scene", "health"),
                null
        );

        assertThat(chat.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(chat).at("/data/healthWarning").asBoolean()).isTrue();
        assertThat(body(chat).at("/data/answer").asText()).contains("执业兽医");
    }

    @Test
    void adminCanUseDashboardStoreManagementAndLivePetAudit() {
        String adminToken = login("admin", "Admin@123456");
        String suffix = String.valueOf(System.nanoTime());

        ResponseEntity<JsonNode> dashboard = exchange(HttpMethod.GET, "/api/v1/admin/dashboard", null, adminToken);

        assertThat(dashboard.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(dashboard).at("/data/userCount").asLong()).isGreaterThanOrEqualTo(2);
        assertThat(body(dashboard).at("/data/productCount").asLong()).isGreaterThanOrEqualTo(1);
        assertThat(body(dashboard).at("/data/generatedAt").asText()).isNotBlank();

        Map<String, Object> storePayload = new LinkedHashMap<>();
        storePayload.put("name", "QA Store " + suffix);
        storePayload.put("address", "QA Road 1");
        storePayload.put("city", "Hangzhou");
        storePayload.put("district", "Xihu");
        storePayload.put("longitude", 120.1500);
        storePayload.put("latitude", 30.2700);
        storePayload.put("phone", "18812340000");
        storePayload.put("businessHours", "09:00-21:00");
        storePayload.put("rating", 4.6);
        storePayload.put("status", "OPEN");
        storePayload.put("featureTags", "QA, grooming");

        ResponseEntity<JsonNode> createdStore = exchange(HttpMethod.POST, "/api/v1/stores", storePayload, adminToken);
        long storeId = body(createdStore).at("/data/id").asLong();

        assertThat(createdStore.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(createdStore).at("/data/name").asText()).contains("QA Store");

        storePayload.put("name", "QA Store Updated " + suffix);
        ResponseEntity<JsonNode> updatedStore = exchange(HttpMethod.PUT, "/api/v1/stores/" + storeId, storePayload, adminToken);

        assertThat(updatedStore.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(updatedStore).at("/data/name").asText()).contains("Updated");

        Map<String, Object> petPayload = new LinkedHashMap<>();
        petPayload.put("storeId", storeId);
        petPayload.put("name", "QA Audit Kitten " + suffix);
        petPayload.put("type", "PET_LIVE");
        petPayload.put("category", "Cat");
        petPayload.put("price", new BigDecimal("1999.00"));
        petPayload.put("stock", 3);
        petPayload.put("status", "ON_SALE");
        petPayload.put("petCode", "AUDIT-PET-" + suffix);
        petPayload.put("breed", "Ragdoll");
        petPayload.put("healthStatus", "Healthy");
        petPayload.put("vaccineCertNo", "VAC-AUDIT-" + suffix);
        petPayload.put("quarantineCertNo", "QUA-AUDIT-" + suffix);
        petPayload.put("traceSource", "QA Store");

        ResponseEntity<JsonNode> createdPet = exchange(HttpMethod.POST, "/api/v1/products", petPayload, adminToken);
        long productId = body(createdPet).at("/data/id").asLong();

        assertThat(createdPet.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(createdPet).at("/data/status").asText()).isEqualTo("DRAFT");
        assertThat(body(createdPet).at("/data/auditStatus").asText()).isEqualTo("PENDING");
        assertThat(body(createdPet).at("/data/stock").asInt()).isEqualTo(1);
        assertThat(body(createdPet).at("/data/livePet/petCode").asText()).startsWith("AUDIT-PET-");

        ResponseEntity<JsonNode> pendingAudits = exchange(
                HttpMethod.GET,
                "/api/v1/products/live-pet-audits?auditStatus=PENDING",
                null,
                adminToken
        );

        assertThat(pendingAudits.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(pendingAudits).at("/data/items").size()).isGreaterThan(0);

        ResponseEntity<JsonNode> auditedPet = exchange(
                HttpMethod.PUT,
                "/api/v1/products/" + productId + "/audit",
                Map.of("approved", true, "remark", "QA audit approved"),
                adminToken
        );

        assertThat(auditedPet.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(auditedPet).at("/data/status").asText()).isEqualTo("ON_SALE");
        assertThat(body(auditedPet).at("/data/auditStatus").asText()).isEqualTo("APPROVED");
        assertThat(body(auditedPet).at("/data/auditedBy").asLong()).isGreaterThan(0);

        ResponseEntity<JsonNode> deletedPet = exchange(HttpMethod.DELETE, "/api/v1/products/" + productId, null, adminToken);
        ResponseEntity<JsonNode> deletedStore = exchange(HttpMethod.DELETE, "/api/v1/stores/" + storeId, null, adminToken);

        assertThat(deletedPet.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(deletedStore.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void adminCanManageUsersAndProductsWithJwt() {
        String adminToken = login("admin", "Admin@123456");
        String suffix = String.valueOf(System.nanoTime());

        Map<String, Object> userPayload = new LinkedHashMap<>();
        userPayload.put("username", "qa_merchant_" + suffix);
        userPayload.put("password", "Qa@123456");
        userPayload.put("displayName", "QA Merchant");
        userPayload.put("phone", "18812345678");
        userPayload.put("email", "qa_" + suffix + "@pet-emarket.local");
        userPayload.put("role", "MERCHANT");
        userPayload.put("memberLevel", "VIP");
        userPayload.put("status", "ACTIVE");

        ResponseEntity<JsonNode> createdUser = exchange(HttpMethod.POST, "/api/v1/users", userPayload, adminToken);
        long userId = body(createdUser).at("/data/id").asLong();

        assertThat(createdUser.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(createdUser).at("/data/role").asText()).isEqualTo("MERCHANT");

        userPayload.put("displayName", "QA Merchant Updated");
        ResponseEntity<JsonNode> updatedUser = exchange(HttpMethod.PUT, "/api/v1/users/" + userId, userPayload, adminToken);

        assertThat(updatedUser.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(updatedUser).at("/data/displayName").asText()).isEqualTo("QA Merchant Updated");

        Map<String, Object> productPayload = new LinkedHashMap<>();
        productPayload.put("name", "QA Live Cat " + suffix);
        productPayload.put("type", "PET_LIVE");
        productPayload.put("category", "Cat");
        productPayload.put("price", new BigDecimal("1888.00"));
        productPayload.put("stock", 5);
        productPayload.put("status", "ON_SALE");
        productPayload.put("petCode", "QA-PET-" + suffix);
        productPayload.put("breed", "Ragdoll");
        productPayload.put("healthStatus", "Healthy");
        productPayload.put("vaccineCertNo", "VAC-" + suffix);
        productPayload.put("quarantineCertNo", "QUA-" + suffix);
        productPayload.put("traceSource", "QA certified store");

        ResponseEntity<JsonNode> createdProduct = exchange(HttpMethod.POST, "/api/v1/products", productPayload, adminToken);
        long productId = body(createdProduct).at("/data/id").asLong();

        assertThat(createdProduct.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(createdProduct).at("/data/stock").asInt()).isEqualTo(1);

        productPayload.put("name", "QA Live Cat Updated " + suffix);
        ResponseEntity<JsonNode> updatedProduct = exchange(HttpMethod.PUT, "/api/v1/products/" + productId, productPayload, adminToken);

        assertThat(updatedProduct.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(body(updatedProduct).at("/data/name").asText()).contains("Updated");

        ResponseEntity<JsonNode> deletedProduct = exchange(HttpMethod.DELETE, "/api/v1/products/" + productId, null, adminToken);
        ResponseEntity<JsonNode> deletedUser = exchange(HttpMethod.DELETE, "/api/v1/users/" + userId, null, adminToken);

        assertThat(deletedProduct.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(deletedUser.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void protectedEndpointsRejectAnonymousAndCustomerProductWrites() {
        ResponseEntity<JsonNode> anonymousUsers = exchange(HttpMethod.GET, "/api/v1/users", null, null);

        assertThat(anonymousUsers.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(body(anonymousUsers).at("/code").asText()).isEqualTo("100401");

        String customerToken = login("demo", "Demo@123456");
        ResponseEntity<JsonNode> customerProductWrite = exchange(
                HttpMethod.POST,
                "/api/v1/products",
                Map.of("name", "Forbidden Item"),
                customerToken
        );

        assertThat(customerProductWrite.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(body(customerProductWrite).at("/code").asText()).isEqualTo("100403");
    }

    private String login(String username, String password) {
        ResponseEntity<JsonNode> response = exchange(
                HttpMethod.POST,
                "/api/v1/auth/login",
                Map.of("username", username, "password", password),
                null
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        String token = body(response).at("/data/token").asText();
        assertThat(token).isNotBlank();
        return token;
    }

    private ResponseEntity<JsonNode> exchange(HttpMethod method, String path, Object payload, String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (token != null) {
            headers.setBearerAuth(token);
        }
        return restTemplate.exchange(path, method, new HttpEntity<>(payload, headers), JsonNode.class);
    }

    private JsonNode body(ResponseEntity<JsonNode> response) {
        assertThat(response.getBody()).isNotNull();
        return response.getBody();
    }
}
