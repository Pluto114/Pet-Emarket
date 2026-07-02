package com.petemarket.server.auth;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.security.JwtService;
import com.petemarket.server.user.AccountStatus;
import com.petemarket.server.user.MemberLevel;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRepository;
import com.petemarket.server.user.UserResponse;
import com.petemarket.server.user.UserRole;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final EmailVerificationService emailVerificationService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       EmailVerificationService emailVerificationService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.emailVerificationService = emailVerificationService;
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        UserAccount user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new BusinessException("100001", "Invalid username or password", HttpStatus.UNAUTHORIZED));
        if (user.getStatus() != AccountStatus.ACTIVE || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BusinessException("100001", "Invalid username or password", HttpStatus.UNAUTHORIZED);
        }
        return new AuthResponse(jwtService.generate(user), UserResponse.from(user));
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.username())) {
            throw new BusinessException("100004", "Username already exists");
        }
        String email = emailVerificationService.normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new BusinessException("100005", "Email already exists");
        }
        emailVerificationService.verifyRegisterCode(email, request.emailCode());

        UserAccount user = new UserAccount();
        user.setUsername(request.username());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(defaultText(request.displayName(), request.username()));
        user.setPhone(defaultText(request.phone(), ""));
        user.setEmail(email);
        user.setRole(UserRole.CUSTOMER);
        user.setMemberLevel(MemberLevel.NORMAL);
        user.setStatus(AccountStatus.ACTIVE);
        userRepository.save(user);
        return new AuthResponse(jwtService.generate(user), UserResponse.from(user));
    }

    public EmailCodeResponse sendEmailCode(SendEmailCodeRequest request) {
        return emailVerificationService.sendRegisterCode(request);
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
