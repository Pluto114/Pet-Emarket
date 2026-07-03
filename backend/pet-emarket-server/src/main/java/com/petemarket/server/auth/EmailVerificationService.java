package com.petemarket.server.auth;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.user.UserRepository;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;

@Service
public class EmailVerificationService {
    private static final Duration CODE_TTL = Duration.ofMinutes(10);
    private static final Duration SEND_COOLDOWN = Duration.ofSeconds(45);
    private static final int MAX_ATTEMPTS = 5;

    private final UserRepository userRepository;
    private final EmailDeliveryService emailDeliveryService;
    private final SecureRandom secureRandom = new SecureRandom();
    private final Map<String, VerificationCode> codes = new ConcurrentHashMap<>();

    public EmailVerificationService(UserRepository userRepository, EmailDeliveryService emailDeliveryService) {
        this.userRepository = userRepository;
        this.emailDeliveryService = emailDeliveryService;
    }

    public EmailCodeResponse sendRegisterCode(SendEmailCodeRequest request) {
        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new BusinessException("100005", "该邮箱已注册，请直接登录或更换邮箱");
        }

        Instant now = Instant.now();
        VerificationCode existing = codes.get(email);
        if (existing != null && existing.sentAt().plus(SEND_COOLDOWN).isAfter(now)) {
            throw new BusinessException("100006", "验证码请求过于频繁，请稍后再试");
        }

        String code = "%06d".formatted(secureRandom.nextInt(1_000_000));
        emailDeliveryService.sendRegisterCode(email, code, (int) CODE_TTL.toSeconds());
        codes.put(email, new VerificationCode(code, now.plus(CODE_TTL), now, 0));
        return new EmailCodeResponse(
                email,
                (int) CODE_TTL.toSeconds(),
                emailDeliveryService.shouldExposeDevCode() ? code : null
        );
    }

    public void verifyRegisterCode(String emailValue, String codeValue) {
        String email = normalizeEmail(emailValue);
        String code = codeValue == null ? "" : codeValue.trim();
        VerificationCode slot = codes.get(email);
        Instant now = Instant.now();

        if (slot == null) {
            throw new BusinessException("100007", "请先获取邮箱验证码");
        }
        if (slot.expiresAt().isBefore(now)) {
            codes.remove(email);
            throw new BusinessException("100008", "邮箱验证码已过期，请重新获取");
        }
        if (!slot.code().equals(code)) {
            int attempts = slot.attempts() + 1;
            if (attempts >= MAX_ATTEMPTS) {
                codes.remove(email);
                throw new BusinessException("100009", "验证码错误次数过多，请重新获取");
            }
            codes.put(email, new VerificationCode(slot.code(), slot.expiresAt(), slot.sentAt(), attempts));
            throw new BusinessException("100010", "邮箱验证码不正确");
        }

        codes.remove(email);
    }

    public String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    private record VerificationCode(String code, Instant expiresAt, Instant sentAt, int attempts) {
    }
}
