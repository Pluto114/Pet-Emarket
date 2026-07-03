package com.petemarket.server.ai;

import org.springframework.stereotype.Service;

@Service
public class AiAssistantService {
    private final AiGatewayClient aiGatewayClient;

    public AiAssistantService(AiGatewayClient aiGatewayClient) {
        this.aiGatewayClient = aiGatewayClient;
    }

    public AiChatResponse chat(AiChatRequest request) {
        return aiGatewayClient.chat(request);
    }
}
