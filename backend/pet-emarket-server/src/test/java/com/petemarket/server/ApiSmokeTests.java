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
