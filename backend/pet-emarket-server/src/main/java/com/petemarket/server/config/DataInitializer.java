package com.petemarket.server.config;

import com.petemarket.server.media.MediaAsset;
import com.petemarket.server.media.MediaAssetRepository;
import com.petemarket.server.media.MediaStatus;
import com.petemarket.server.media.MediaType;
import com.petemarket.server.product.Product;
import com.petemarket.server.product.ProductAuditStatus;
import com.petemarket.server.product.ProductRepository;
import com.petemarket.server.product.ProductStatus;
import com.petemarket.server.product.ProductType;
import com.petemarket.server.store.PetStore;
import com.petemarket.server.store.PetStoreRepository;
import com.petemarket.server.store.StoreStatus;
import com.petemarket.server.user.AccountStatus;
import com.petemarket.server.user.MemberLevel;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRepository;
import com.petemarket.server.user.UserRole;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataInitializer {
    @Bean
    CommandLineRunner seedData(UserRepository userRepository,
                               ProductRepository productRepository,
                               PetStoreRepository storeRepository,
                               MediaAssetRepository mediaAssetRepository,
                               PasswordEncoder passwordEncoder) {
        return args -> {
            if (!userRepository.existsByUsername("admin")) {
                userRepository.save(user("admin", "Admin@123456", "System Admin", UserRole.ADMIN, MemberLevel.SVIP, passwordEncoder));
            }
            if (!userRepository.existsByUsername("demo")) {
                userRepository.save(user("demo", "Demo@123456", "Demo User", UserRole.CUSTOMER, MemberLevel.VIP, passwordEncoder));
            }
            if (!userRepository.existsByUsername("merchant")) {
                userRepository.save(user("merchant", "Merchant@123456", "Demo Merchant", UserRole.MERCHANT, MemberLevel.VIP, passwordEncoder));
            }
            Long merchantId = userRepository.findByUsername("merchant").map(UserAccount::getId).orElse(null);

            List<PetStore> stores = storeRepository.count() == 0
                    ? storeRepository.saveAll(List.of(
                    store("PetJoy Hangzhou Hub", "Hangzhou", "Xihu", "No. 18 Wensan Road", 120.1551, 30.2741,
                            "18800001001", "09:00-21:00", 4.9, "Certified live pets, grooming, food"),
                    store("PawCare West Lake Store", "Hangzhou", "Xihu", "No. 66 Longjing Road", 120.1400, 30.2500,
                            "18800001002", "09:30-20:30", 4.8, "Cat care, vaccine consulting, fast delivery"),
                    store("MeowLife Binjiang Store", "Hangzhou", "Binjiang", "No. 88 Jiangnan Avenue", 120.2100, 30.2100,
                            "18800001003", "10:00-22:00", 4.7, "Dog goods, toys, member service")
            ))
                    : storeRepository.findAll();
            if (merchantId != null) {
                boolean updatedOwner = false;
                for (PetStore store : stores) {
                    if (store.getOwnerUserId() == null) {
                        store.setOwnerUserId(merchantId);
                        updatedOwner = true;
                    }
                }
                if (updatedOwner) {
                    stores = storeRepository.saveAll(stores);
                }
            }

            if (productRepository.count() == 0) {
                Long storeA = stores.get(0).getId();
                Long storeB = stores.size() > 1 ? stores.get(1).getId() : storeA;
                Long storeC = stores.size() > 2 ? stores.get(2).getId() : storeA;

                Product cat = product("British Shorthair Kitten", ProductType.PET_LIVE, "Cat", new BigDecimal("2680.00"), 1, storeA);
                cat.setDescription("Vaccinated kitten with quarantine certificate and trace record.");
                cat.setPetCode("PET-CAT-0001");
                cat.setBreed("British Shorthair");
                cat.setHealthStatus("Healthy");
                cat.setVaccineCertNo("VAC-2026-0001");
                cat.setQuarantineCertNo("QUA-2026-0001");
                cat.setTraceSource("PetJoy Hangzhou Hub");
                productRepository.save(cat);

                Product ragdoll = product("Ragdoll Kitten", ProductType.PET_LIVE, "Cat", new BigDecimal("3980.00"), 1, storeB);
                ragdoll.setDescription("Gentle ragdoll kitten with full vaccine and quarantine records.");
                ragdoll.setPetCode("PET-CAT-0002");
                ragdoll.setBreed("Ragdoll");
                ragdoll.setHealthStatus("Healthy");
                ragdoll.setVaccineCertNo("VAC-2026-0002");
                ragdoll.setQuarantineCertNo("QUA-2026-0002");
                ragdoll.setTraceSource("PawCare West Lake Store");
                productRepository.save(ragdoll);

                Product puppy = product("Corgi Puppy", ProductType.PET_LIVE, "Dog", new BigDecimal("3280.00"), 1, storeC);
                puppy.setDescription("Energetic corgi puppy with health check report.");
                puppy.setPetCode("PET-DOG-0001");
                puppy.setBreed("Corgi");
                puppy.setHealthStatus("Healthy");
                puppy.setVaccineCertNo("VAC-2026-0003");
                puppy.setQuarantineCertNo("QUA-2026-0003");
                puppy.setTraceSource("MeowLife Binjiang Store");
                productRepository.save(puppy);

                Product food = product("Premium Cat Food 2kg", ProductType.GOODS, "Food", new BigDecimal("129.00"), 88, storeA);
                food.setDescription("High protein daily food for young cats.");
                productRepository.save(food);

                Product care = product("Daily Pet Care Kit", ProductType.GOODS, "Care", new BigDecimal("89.00"), 64, storeB);
                care.setDescription("Comb, nail clipper, bath towel and basic care supplies.");
                productRepository.save(care);

                Product toy = product("Interactive Dog Toy", ProductType.GOODS, "Toy", new BigDecimal("59.00"), 45, storeC);
                toy.setDescription("Durable toy for dog training and daily companionship.");
                productRepository.save(toy);
            }

            // Seed demo media assets
            if (mediaAssetRepository.count() == 0) {
                MediaAsset video = new MediaAsset();
                video.setTitle("New Kitten Care Guide");
                video.setMediaType(MediaType.VIDEO);
                video.setUrl("https://www.w3schools.com/html/mov_bbb.mp4");
                video.setCoverUrl("");
                video.setDescription("Demo video for live pet onboarding and health care tips.");
                video.setStatus(MediaStatus.APPROVED);
                video.setAuditRemark("Seed media approved");
                mediaAssetRepository.save(video);

                MediaAsset image = new MediaAsset();
                image.setTitle("Pet-Emarket Home Banner");
                image.setMediaType(MediaType.IMAGE);
                image.setUrl("https://via.placeholder.com/800x400.png?text=PetEmarket");
                image.setCoverUrl("");
                image.setDescription("Demo marketing image for the home page.");
                image.setStatus(MediaStatus.APPROVED);
                image.setAuditRemark("Seed media approved");
                mediaAssetRepository.save(image);
            }

            List<Product> zeroStockOnSaleProducts = productRepository.findAll().stream()
                    .filter(product -> product.getStock() != null && product.getStock() <= 0)
                    .filter(product -> product.getStatus() == ProductStatus.ON_SALE)
                    .toList();
            if (!zeroStockOnSaleProducts.isEmpty()) {
                zeroStockOnSaleProducts.forEach(product -> product.setStatus(ProductStatus.OFF_SALE));
                productRepository.saveAll(zeroStockOnSaleProducts);
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

    private PetStore store(String name,
                           String city,
                           String district,
                           String address,
                           double longitude,
                           double latitude,
                           String phone,
                           String businessHours,
                           double rating,
                           String featureTags) {
        PetStore store = new PetStore();
        store.setName(name);
        store.setCity(city);
        store.setDistrict(district);
        store.setAddress(address);
        store.setLongitude(longitude);
        store.setLatitude(latitude);
        store.setPhone(phone);
        store.setBusinessHours(businessHours);
        store.setRating(rating);
        store.setStatus(StoreStatus.OPEN);
        store.setFeatureTags(featureTags);
        return store;
    }

    private Product product(String name, ProductType type, String category, BigDecimal price, int stock, Long storeId) {
        Product product = new Product();
        product.setName(name);
        product.setType(type);
        product.setCategory(category);
        product.setPrice(price);
        product.setStock(stock);
        product.setStatus(ProductStatus.ON_SALE);
        product.setStoreId(storeId);
        product.setAuditStatus(type == ProductType.PET_LIVE ? ProductAuditStatus.APPROVED : ProductAuditStatus.NOT_REQUIRED);
        product.setAuditRemark(type == ProductType.PET_LIVE ? "Seed data approved" : "");
        return product;
    }

}
