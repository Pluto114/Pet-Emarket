package com.petemarket.server.config;

import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductStatus;
import com.petemarket.server.product.ProductType;
import com.petemarket.server.user.AccountStatus;
import com.petemarket.server.user.MemberLevel;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRepository;
import com.petemarket.server.user.UserRole;
import java.math.BigDecimal;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataInitializer {
    @Bean
    CommandLineRunner seedData(UserRepository userRepository,
                               ProductRepository productRepository,
                               PasswordEncoder passwordEncoder) {
        return args -> {
            if (!userRepository.existsByUsername("admin")) {
                userRepository.save(user("admin", "Admin@123456", "System Admin", UserRole.ADMIN, MemberLevel.SVIP, passwordEncoder));
            }
            if (!userRepository.existsByUsername("demo")) {
                userRepository.save(user("demo", "Demo@123456", "Demo User", UserRole.CUSTOMER, MemberLevel.VIP, passwordEncoder));
            }
            if (productRepository.count() == 0) {
                Product cat = product("British Shorthair Kitten", ProductType.PET_LIVE, "Cat", new BigDecimal("2680.00"), 1);
                cat.setDescription("Vaccinated kitten with quarantine certificate and trace record.");
                cat.setPetCode("PET-CAT-0001");
                cat.setBreed("British Shorthair");
                cat.setHealthStatus("Healthy");
                cat.setVaccineCertNo("VAC-2026-0001");
                cat.setQuarantineCertNo("QUA-2026-0001");
                cat.setTraceSource("Demo certified pet store");
                productRepository.save(cat);

                Product food = product("Premium Cat Food 2kg", ProductType.GOODS, "Food", new BigDecimal("129.00"), 88);
                food.setDescription("High protein daily food for young cats.");
                productRepository.save(food);
            }
        };
    }

    private UserAccount user(String username,
                             String password,
                             String displayName,
                             UserRole role,
                             MemberLevel memberLevel,
                             PasswordEncoder passwordEncoder) {
        UserAccount user = new UserAccount();
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setDisplayName(displayName);
        user.setPhone("18800000000");
        user.setEmail(username + "@pet-emarket.local");
        user.setRole(role);
        user.setMemberLevel(memberLevel);
        user.setStatus(AccountStatus.ACTIVE);
        return user;
    }

    private Product product(String name, ProductType type, String category, BigDecimal price, int stock) {
        Product product = new Product();
        product.setName(name);
        product.setType(type);
        product.setCategory(category);
        product.setPrice(price);
        product.setStock(stock);
        product.setStatus(ProductStatus.ON_SALE);
        product.setStoreId(1L);
        return product;
    }
}
