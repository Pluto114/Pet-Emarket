package com.petemarket.server.user;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.BusinessException;
import com.petemarket.server.common.PageData;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ApiResponse<PageData<UserResponse>> list(@AuthenticationPrincipal UserAccount currentUser) {
        requireAdmin(currentUser);
        return ApiResponse.ok(PageData.of(userService.list()));
    }

    @PostMapping
    public ApiResponse<UserResponse> create(@AuthenticationPrincipal UserAccount currentUser,
                                            @Valid @RequestBody UpsertUserRequest request) {
        requireAdmin(currentUser);
        return ApiResponse.ok(userService.create(request), "user created");
    }

    @GetMapping("/{id}")
    public ApiResponse<UserResponse> get(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        requireSelfOrAdmin(currentUser, id);
        return ApiResponse.ok(userService.get(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<UserResponse> update(@AuthenticationPrincipal UserAccount currentUser,
                                            @PathVariable Long id,
                                            @Valid @RequestBody UpsertUserRequest request) {
        requireSelfOrAdmin(currentUser, id);
        boolean adminUpdate = currentUser.getRole() == UserRole.ADMIN;
        return ApiResponse.ok(userService.update(id, request, adminUpdate), "user updated");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@AuthenticationPrincipal UserAccount currentUser, @PathVariable Long id) {
        requireAdmin(currentUser);
        userService.delete(id);
        return ApiResponse.ok(null, "user deleted");
    }

    private void requireAdmin(UserAccount user) {
        if (user.getRole() != UserRole.ADMIN) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }

    private void requireSelfOrAdmin(UserAccount user, Long id) {
        if (user.getRole() != UserRole.ADMIN && !user.getId().equals(id)) {
            throw new BusinessException("100403", "Forbidden", HttpStatus.FORBIDDEN);
        }
    }
}
