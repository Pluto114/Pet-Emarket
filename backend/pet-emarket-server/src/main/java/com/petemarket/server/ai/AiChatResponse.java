package com.petemarket.server.ai;

import java.util.List;

public record AiChatResponse(
        String answer,
        List<String> knowledgeTags,
        List<String> recommendedActions,
        boolean healthWarning
) {
}
