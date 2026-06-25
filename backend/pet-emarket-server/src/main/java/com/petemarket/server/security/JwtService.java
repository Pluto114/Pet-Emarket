package com.petemarket.server.security;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.config.PetEmarketProperties;
import com.petemarket.server.user.UserAccount;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private final PetEmarketProperties properties;

    public JwtService(PetEmarketProperties properties) {
        this.properties = properties;
    }

    public String generate(UserAccount user) {
        try {
            Map<String, Object> header = Map.of("alg", "HS256", "typ", "JWT");
            long now = Instant.now().getEpochSecond();
            Map<String, Object> payload = new HashMap<>();
            payload.put("sub", user.getId());
            payload.put("username", user.getUsername());
            payload.put("role", user.getRole().name());
            payload.put("iat", now);
            payload.put("exp", now + properties.getJwt().getTtlSeconds());

            String unsigned = base64Url(OBJECT_MAPPER.writeValueAsBytes(header))
                    + "."
                    + base64Url(OBJECT_MAPPER.writeValueAsBytes(payload));
            return unsigned + "." + sign(unsigned);
        } catch (Exception exception) {
            throw new BusinessException("100500", "Token generation failed");
        }
    }

    public Long verifyAndGetUserId(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new IllegalArgumentException("Invalid token");
            }
            String unsigned = parts[0] + "." + parts[1];
            if (!constantEquals(parts[2], sign(unsigned))) {
                throw new IllegalArgumentException("Invalid token signature");
            }
            Map<String, Object> payload = OBJECT_MAPPER.readValue(
                    Base64.getUrlDecoder().decode(parts[1]),
                    new TypeReference<>() {
                    }
            );
            long exp = ((Number) payload.get("exp")).longValue();
            if (exp < Instant.now().getEpochSecond()) {
                throw new IllegalArgumentException("Token expired");
            }
            return ((Number) payload.get("sub")).longValue();
        } catch (Exception exception) {
            throw new BusinessException("100003", "Invalid or expired token", HttpStatus.UNAUTHORIZED);
        }
    }

    private String sign(String unsigned) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(properties.getJwt().getSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return base64Url(mac.doFinal(unsigned.getBytes(StandardCharsets.UTF_8)));
    }

    private String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private boolean constantEquals(String a, String b) {
        byte[] left = a.getBytes(StandardCharsets.UTF_8);
        byte[] right = b.getBytes(StandardCharsets.UTF_8);
        if (left.length != right.length) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < left.length; i++) {
            result |= left[i] ^ right[i];
        }
        return result == 0;
    }
}
