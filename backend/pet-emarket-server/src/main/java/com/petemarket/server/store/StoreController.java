package com.petemarket.server.store;

import com.petemarket.server.common.ApiResponse;
import com.petemarket.server.common.PageData;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/stores")
public class StoreController {
    private final StoreService storeService;

    public StoreController(StoreService storeService) {
        this.storeService = storeService;
    }

    @GetMapping
    public ApiResponse<PageData<StoreResponse>> list() {
        return ApiResponse.ok(PageData.of(storeService.listOpenStores()));
    }

    @GetMapping("/nearby")
    public ApiResponse<PageData<StoreResponse>> nearby(@RequestParam double longitude,
                                                       @RequestParam double latitude,
                                                       @RequestParam(defaultValue = "10") double radiusKm,
                                                       @RequestParam(required = false) String keyword) {
        return ApiResponse.ok(PageData.of(storeService.nearby(longitude, latitude, radiusKm, keyword)));
    }
}
