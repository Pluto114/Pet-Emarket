package com.petemarket.server.user;

import com.petemarket.server.common.BusinessException;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public List<UserResponse> list() {
        return userRepository.findAll().stream().map(UserResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public UserResponse get(Long id) {
        return UserResponse.from(find(id));
    }

    @Transactional
    public UserResponse create(UpsertUserRequest request) {
        if (request.username() == null || request.username().isBlank()) {
            throw new BusinessException("100001", "Username is required");
        }
        if (userRepository.existsByUsername(request.username())) {
            throw new BusinessException("100004", "Username already exists");
        }
        UserAccount user = new UserAccount();
        user.setUsername(request.username());
        user.setPasswordHash(passwordEncoder.encode(defaultText(request.password(), "ChangeMe@123456")));
        apply(user, request, true);
        userRepository.save(user);
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse update(Long id, UpsertUserRequest request, boolean adminUpdate) {
        UserAccount user = find(id);
        if (request.displayName() != null && !request.displayName().isBlank()) {
            user.setDisplayName(request.displayName());
        }
        if (request.phone() != null) {
            user.setPhone(request.phone());
        }
        if (request.email() != null) {
            user.setEmail(request.email());
        }
        if (request.password() != null && !request.password().isBlank()) {
            user.setPasswordHash(passwordEncoder.encode(request.password()));
        }
        if (adminUpdate) {
            apply(user, request, false);
        }
        userRepository.save(user);
        return UserResponse.from(user);
    }

    @Transactional
    public void delete(Long id) {
        userRepository.delete(find(id));
    }

    public UserAccount find(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new BusinessException("100404", "User not found", HttpStatus.NOT_FOUND));
    }

    private void apply(UserAccount user, UpsertUserRequest request, boolean creating) {
        if (creating) {
            user.setDisplayName(defaultText(request.displayName(), request.username()));
            user.setPhone(defaultText(request.phone(), ""));
            user.setEmail(defaultText(request.email(), ""));
        }
        user.setRole(request.role() == null ? UserRole.CUSTOMER : request.role());
        user.setMemberLevel(request.memberLevel() == null ? MemberLevel.NORMAL : request.memberLevel());
        user.setStatus(request.status() == null ? AccountStatus.ACTIVE : request.status());
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
