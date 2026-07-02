package com.petemarket.server.store;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "pet_store")
public class PetStore {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 128)
    private String name;

    @Column(nullable = false, length = 255)
    private String address;

    @Column(nullable = false, length = 64)
    private String city;

    @Column(nullable = false, length = 64)
    private String district;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private Double latitude;

    @Column(length = 32)
    private String phone;

    @Column(length = 64)
    private String businessHours;

    @Column(nullable = false)
    private Double rating = 5.0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StoreStatus status = StoreStatus.OPEN;

    @Column(length = 500)
    private String featureTags;

    @Column(length = 64)
    private String amapPoiId;

    private Instant createdAt;
    private Instant updatedAt;

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getDistrict() {
        return district;
    }

    public void setDistrict(String district) {
        this.district = district;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getBusinessHours() {
        return businessHours;
    }

    public void setBusinessHours(String businessHours) {
        this.businessHours = businessHours;
    }

    public Double getRating() {
        return rating;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public StoreStatus getStatus() {
        return status;
    }

    public void setStatus(StoreStatus status) {
        this.status = status;
    }

    public String getFeatureTags() {
        return featureTags;
    }

    public void setFeatureTags(String featureTags) {
        this.featureTags = featureTags;
    }

    public String getAmapPoiId() {
        return amapPoiId;
    }

    public void setAmapPoiId(String amapPoiId) {
        this.amapPoiId = amapPoiId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
