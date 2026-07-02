package com.petemarket.server.geo;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/geo/amap")
public class AmapController {
    private final AmapService amapService;

    public AmapController(AmapService amapService) {
        this.amapService = amapService;
    }

    @GetMapping("/nearby-pet-stores")
    public ApiResponse<PageData<AmapPoiResponse>> nearbyPetStores(
            @RequestParam double longitude,
            @RequestParam double latitude,
            @RequestParam(defaultValue = "5000") int radius,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String keywords) {
        return ApiResponse.ok(PageData.of(amapService.nearbyPetStores(longitude, latitude, radius, limit, keywords)));
    }

    @GetMapping("/geocode")
    public ApiResponse<AmapGeocodeResponse> geocode(@RequestParam String address,
                                                    @RequestParam(required = false) String city) {
        return ApiResponse.ok(amapService.geocode(address, city));
    }

    @GetMapping("/regeo")
    public ApiResponse<AmapGeocodeResponse> reverseGeocode(@RequestParam double longitude,
                                                           @RequestParam double latitude) {
        return ApiResponse.ok(amapService.reverseGeocode(longitude, latitude));
    }
}
