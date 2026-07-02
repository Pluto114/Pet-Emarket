package com.petemarket.server.merchant;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.store.PetStore;
import com.petemarket.server.store.PetStoreRepository;
import com.petemarket.server.store.StoreStatus;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRepository;
import com.petemarket.server.user.UserRole;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantApplicationService {
    private final MerchantApplicationRepository applicationRepository;
    private final UserRepository userRepository;
    private final PetStoreRepository storeRepository;

    public MerchantApplicationService(MerchantApplicationRepository applicationRepository,
                                      UserRepository userRepository,
                                      PetStoreRepository storeRepository) {
        this.applicationRepository = applicationRepository;
        this.userRepository = userRepository;
        this.storeRepository = storeRepository;
    }

    @Transactional
    public MerchantApplicationResponse submit(UserAccount currentUser, MerchantApplicationRequest request) {
        if (currentUser.getRole() == UserRole.ADMIN || currentUser.getRole() == UserRole.MERCHANT) {
            throw new BusinessException("400001", "Current account is already a manager", HttpStatus.CONFLICT);
        }
        if (applicationRepository.existsByUserIdAndStatus(currentUser.getId(), MerchantApplicationStatus.PENDING)) {
            throw new BusinessException("400002", "A pending merchant application already exists", HttpStatus.CONFLICT);
        }

        MerchantApplication application = new MerchantApplication();
        application.setUserId(currentUser.getId());
        application.setStoreName(request.storeName());
        application.setCity(request.city());
        application.setDistrict(request.district());
        application.setAddress(request.address());
        application.setLongitude(request.longitude());
        application.setLatitude(request.latitude());
        application.setContactName(defaultText(request.contactName(), currentUser.getDisplayName()));
        application.setContactPhone(defaultText(request.contactPhone(), currentUser.getPhone()));
        application.setBusinessLicenseNo(defaultText(request.businessLicenseNo(), ""));
        application.setReason(defaultText(request.reason(), ""));
        applicationRepository.save(application);
        return MerchantApplicationResponse.from(application);
    }

    @Transactional(readOnly = true)
    public List<MerchantApplicationResponse> listMine(UserAccount currentUser) {
        return applicationRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId()).stream()
                .map(MerchantApplicationResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MerchantApplicationResponse> listAll(MerchantApplicationStatus status) {
        List<MerchantApplication> applications = status == null
                ? applicationRepository.findAllByOrderByCreatedAtDesc()
                : applicationRepository.findByStatusOrderByCreatedAtDesc(status);
        return applications.stream().map(MerchantApplicationResponse::from).toList();
    }

    @Transactional
    public MerchantApplicationResponse audit(Long id, MerchantAuditRequest request, UserAccount auditor) {
        MerchantApplication application = applicationRepository.findById(id)
                .orElseThrow(() -> new BusinessException("400404", "Merchant application not found", HttpStatus.NOT_FOUND));
        if (application.getStatus() != MerchantApplicationStatus.PENDING) {
            throw new BusinessException("400409", "Application has already been audited", HttpStatus.CONFLICT);
        }

        boolean approved = Boolean.TRUE.equals(request.approved());
        application.setStatus(approved ? MerchantApplicationStatus.APPROVED : MerchantApplicationStatus.REJECTED);
        application.setAuditRemark(defaultText(request.remark(), approved ? "审核通过" : "审核驳回"));
        application.setAuditedBy(auditor.getId());
        application.setAuditedAt(Instant.now());

        if (approved) {
            UserAccount applicant = userRepository.findById(application.getUserId())
                    .orElseThrow(() -> new BusinessException("100404", "User not found", HttpStatus.NOT_FOUND));
            applicant.setRole(UserRole.MERCHANT);
            PetStore store = new PetStore();
            store.setName(application.getStoreName());
            store.setCity(application.getCity());
            store.setDistrict(application.getDistrict());
            store.setAddress(application.getAddress());
            store.setLongitude(application.getLongitude());
            store.setLatitude(application.getLatitude());
            store.setPhone(defaultText(application.getContactPhone(), ""));
            store.setBusinessHours("09:00-21:00");
            store.setRating(5.0);
            store.setStatus(StoreStatus.OPEN);
            store.setFeatureTags("商家入驻");
            store.setAmapPoiId("");
            store.setOwnerUserId(applicant.getId());
            storeRepository.save(store);
            application.setStoreId(store.getId());
        }

        return MerchantApplicationResponse.from(application);
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
