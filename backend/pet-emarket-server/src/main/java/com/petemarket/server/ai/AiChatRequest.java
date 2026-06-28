package com.petemarket.server.ai;

import jakarta.validation.constraints.NotBlank;

public record AiChatRequest(
        @NotBlank String question,
        String scene
) {
}
