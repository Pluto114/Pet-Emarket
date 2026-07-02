package com.petemarket.server.geo;

public record AmapGeocodeResponse(
        String formattedAddress,
        String province,
        String city,
        String district,
        String longitude,
        String latitude
) {
}
