package com.petemarket.server.ai;

import com.petemarket.server.config.PetEmarketProperties;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Component
public class AiGatewayClient {
    private final PetEmarketProperties properties;
    private final RestTemplateBuilder restTemplateBuilder;

    public AiGatewayClient(PetEmarketProperties properties, RestTemplateBuilder restTemplateBuilder) {
        this.properties = properties;
        this.restTemplateBuilder = restTemplateBuilder;
    }

    public Optional<AiChatResponse> chat(AiChatRequest request) {
        PetEmarketProperties.AiService config = properties.getAiService();
        if (!config.isEnabled()) {
            return Optional.empty();
        }
        try {
            RestTemplate restTemplate = restTemplateBuilder
                    .rootUri(config.getBaseUrl())
                    .setConnectTimeout(Duration.ofSeconds(config.getTimeoutSeconds()))
                    .setReadTimeout(Duration.ofSeconds(config.getTimeoutSeconds()))
                    .build();
            Map<String, Object> payload = Map.of(
                    "userId", "java-backend-gateway",
                    "question", request.question(),
                    "context", Map.of("scene", request.scene() == null ? "general" : request.scene())
            );
            Map<?, ?> response = restTemplate.postForObject("/api/v1/chat", payload, Map.class);
            return parseResponse(response);
        } catch (RestClientException | ClassCastException exception) {
            return Optional.empty();
        }
    }

    private Optional<AiChatResponse> parseResponse(Map<?, ?> response) {
        if (response == null || Boolean.FALSE.equals(response.get("success"))) {
            return Optional.empty();
        }
        Object dataValue = response.get("data");
        if (!(dataValue instanceof Map<?, ?> data)) {
            return Optional.empty();
        }
        String answer = text(data.get("answer"));
        String disclaimer = text(data.get("disclaimer"));
        if (answer.isBlank()) {
            return Optional.empty();
        }
        if (!disclaimer.isBlank() && !answer.contains(disclaimer)) {
            answer = answer + "\n\n" + disclaimer;
        }
        String answerSource = text(data.get("answerSource"));
        List<String> knowledgeTags = knowledgeTags(data.get("sources"), answerSource);
        List<String> recommendedActions = recommendedActions(data.get("relatedProducts"), answerSource);
        boolean healthWarning = !disclaimer.isBlank() || answer.contains("兽医");
        return Optional.of(new AiChatResponse(answer, knowledgeTags, recommendedActions, healthWarning));
    }

    private List<String> knowledgeTags(Object sourcesValue, String answerSource) {
        List<String> tags = new ArrayList<>();
        if ("knowledge_base".equals(answerSource)) {
            tags.add("RAG 知识库");
        } else if ("template".equals(answerSource)) {
            tags.add("业务模板");
        } else if (!answerSource.isBlank()) {
            tags.add("AI 模型");
        }
        if (sourcesValue instanceof List<?> sources) {
            for (Object source : sources) {
                if (source instanceof Map<?, ?> sourceMap) {
                    String title = text(sourceMap.get("title"));
                    if (!title.isBlank()) {
                        tags.add(title);
                    }
                }
            }
        }
        return tags.isEmpty() ? List.of("AI Gateway") : tags;
    }

    private List<String> recommendedActions(Object relatedProductsValue, String answerSource) {
        if (relatedProductsValue instanceof List<?> products && !products.isEmpty()) {
            return products.stream()
                    .map(this::text)
                    .filter(value -> !value.isBlank())
                    .map(value -> "查看关联商品：" + value)
                    .toList();
        }
        if ("template".equals(answerSource)) {
            return List.of("打开订单页查看状态", "需要售后时提交退款原因");
        }
        return List.of("查看推荐页获取商品建议", "补充宠物年龄、品种和预算");
    }

    private String text(Object value) {
        return value == null ? "" : value.toString();
    }
}
