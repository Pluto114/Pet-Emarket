package com.petemarket.server.geo;

public record AmapPoiResponse(
        String poiId,
        String name,
        String type,
        String typeCode,
        String address,
        String province,
        String city,
        String district,
        String longitude,
        String latitude,
        String phone,
        Double distanceMeters
) {
}
