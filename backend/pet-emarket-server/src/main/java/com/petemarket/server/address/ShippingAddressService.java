package com.petemarket.server.address;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.order.AddressSnapshot;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ShippingAddressService {
    private final ShippingAddressRepository shippingAddressRepository;

    public ShippingAddressService(ShippingAddressRepository shippingAddressRepository) {
        this.shippingAddressRepository = shippingAddressRepository;
    }

    @Transactional(readOnly = true)
    public List<ShippingAddressResponse> list(Long userId) {
        return shippingAddressRepository.findByUserIdOrderByDefaultAddressDescUpdatedAtDesc(userId)
                .stream()
                .map(ShippingAddressResponse::from)
                .toList();
    }

    @Transactional
    public ShippingAddressResponse create(Long userId, UpsertShippingAddressRequest request) {
        ShippingAddress address = new ShippingAddress();
        address.setUserId(userId);
        boolean firstAddress = shippingAddressRepository.countByUserId(userId) == 0;
        apply(address, request, firstAddress || Boolean.TRUE.equals(request.defaultAddress()));
        shippingAddressRepository.save(address);
        return ShippingAddressResponse.from(address);
    }

    @Transactional
    public ShippingAddressResponse update(Long userId, Long id, UpsertShippingAddressRequest request) {
        ShippingAddress address = findOwned(userId, id);
        apply(address, request, Boolean.TRUE.equals(request.defaultAddress()));
        return ShippingAddressResponse.from(address);
    }

    @Transactional
    public ShippingAddressResponse setDefault(Long userId, Long id) {
        ShippingAddress address = findOwned(userId, id);
        markOnlyDefault(userId, address);
        return ShippingAddressResponse.from(address);
    }

    @Transactional
    public void delete(Long userId, Long id) {
        ShippingAddress address = findOwned(userId, id);
        boolean wasDefault = Boolean.TRUE.equals(address.getDefaultAddress());
        shippingAddressRepository.delete(address);
        shippingAddressRepository.flush();
        if (wasDefault) {
            shippingAddressRepository.findByUserIdOrderByDefaultAddressDescUpdatedAtDesc(userId)
                    .stream()
                    .findFirst()
                    .ifPresent(next -> markOnlyDefault(userId, next));
        }
    }

    @Transactional(readOnly = true)
    public AddressSnapshot snapshot(Long userId, Long addressId) {
        ShippingAddress address = findOwned(userId, addressId);
        return toSnapshot(address);
    }

    @Transactional(readOnly = true)
    public AddressSnapshot defaultSnapshot(Long userId) {
        return shippingAddressRepository.findByUserIdOrderByDefaultAddressDescUpdatedAtDesc(userId)
                .stream()
                .findFirst()
                .map(this::toSnapshot)
                .orElse(null);
    }

    private void apply(ShippingAddress address, UpsertShippingAddressRequest request, boolean makeDefault) {
        address.setReceiver(request.receiver().trim());
        address.setPhone(request.phone().trim());
        address.setProvince(defaultText(request.province(), ""));
        address.setCity(defaultText(request.city(), ""));
        address.setDistrict(defaultText(request.district(), ""));
        address.setDetail(request.detail().trim());
        if (makeDefault) {
            markOnlyDefault(address.getUserId(), address);
        }
    }

    private void markOnlyDefault(Long userId, ShippingAddress target) {
        shippingAddressRepository.findByUserIdOrderByDefaultAddressDescUpdatedAtDesc(userId)
                .forEach(address -> address.setDefaultAddress(address == target || address.getId().equals(target.getId())));
        target.setDefaultAddress(true);
    }

    private ShippingAddress findOwned(Long userId, Long id) {
        return shippingAddressRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new BusinessException("100404", "Shipping address not found", HttpStatus.NOT_FOUND));
    }

    private AddressSnapshot toSnapshot(ShippingAddress address) {
        String detail = String.join(" ",
                defaultText(address.getProvince(), ""),
                defaultText(address.getCity(), ""),
                defaultText(address.getDistrict(), ""),
                defaultText(address.getDetail(), "")
        ).replaceAll("\\s+", " ").trim();
        return new AddressSnapshot(address.getReceiver(), address.getPhone(), detail);
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }
}
