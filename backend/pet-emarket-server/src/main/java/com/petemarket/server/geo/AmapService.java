package com.petemarket.server.geo;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.config.PetEmarketProperties;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@Service
public class AmapService {
    private static final String PET_STORE_KEYWORDS = "宠物店|宠物用品|宠物生活馆|宠物服务";
    private static final String PET_STORE_TYPES = "071500|071501|071502|071503|071504|071505|071506|071507|071508|071509";

    private final PetEmarketProperties properties;
    private final RestTemplateBuilder restTemplateBuilder;

    public AmapService(PetEmarketProperties properties, RestTemplateBuilder restTemplateBuilder) {
        this.properties = properties;
        this.restTemplateBuilder = restTemplateBuilder;
    }

    public List<AmapPoiResponse> nearbyPetStores(double longitude,
                                                 double latitude,
                                                 int radius,
                                                 int limit,
                                                 String keywords) {
        int normalizedRadius = Math.min(Math.max(radius, 100), 50_000);
        int normalizedLimit = Math.min(Math.max(limit, 1), 25);
        String uri = UriComponentsBuilder.fromPath("/v5/place/around")
                .queryParam("key", apiKey())
                .queryParam("location", longitude + "," + latitude)
                .queryParam("radius", normalizedRadius)
                .queryParam("keywords", isBlank(keywords) ? PET_STORE_KEYWORDS : keywords.trim())
                .queryParam("types", PET_STORE_TYPES)
                .queryParam("page_size", normalizedLimit)
                .queryParam("show_fields", "business,photos")
                .build()
                .encode()
                .toUriString();

        Map<?, ?> response = get(uri);
        ensureSuccess(response);
        Object poisValue = response.get("pois");
        if (!(poisValue instanceof List<?> pois)) {
            return List.of();
        }

        List<AmapPoiResponse> results = new ArrayList<>();
        for (Object value : pois) {
            if (value instanceof Map<?, ?> poi) {
                results.add(toPoi(poi));
            }
        }
        return results;
    }

    public AmapGeocodeResponse geocode(String address, String city) {
        if (isBlank(address)) {
            throw new BusinessException("300001", "Address is required");
        }
        UriComponentsBuilder builder = UriComponentsBuilder.fromPath("/v3/geocode/geo")
                .queryParam("key", apiKey())
                .queryParam("address", address.trim());
        if (!isBlank(city)) {
            builder.queryParam("city", city.trim());
        }

        Map<?, ?> response = get(builder.build().encode().toUriString());
        ensureSuccess(response);
        Object geocodesValue = response.get("geocodes");
        if (!(geocodesValue instanceof List<?> geocodes) || geocodes.isEmpty() || !(geocodes.get(0) instanceof Map<?, ?> item)) {
            throw new BusinessException("300004", "No geocode result found", HttpStatus.NOT_FOUND);
        }
        String[] location = splitLocation(text(item.get("location")));
        return new AmapGeocodeResponse(
                text(item.get("formatted_address")),
                text(item.get("province")),
                text(item.get("city")),
                text(item.get("district")),
                location[0],
                location[1]
        );
    }

    public AmapGeocodeResponse reverseGeocode(double longitude, double latitude) {
        String uri = UriComponentsBuilder.fromPath("/v3/geocode/regeo")
                .queryParam("key", apiKey())
                .queryParam("location", longitude + "," + latitude)
                .queryParam("extensions", "base")
                .build()
                .encode()
                .toUriString();
        Map<?, ?> response = get(uri);
        ensureSuccess(response);
        Object regeocodeValue = response.get("regeocode");
        if (!(regeocodeValue instanceof Map<?, ?> regeocode)) {
            throw new BusinessException("300005", "No reverse geocode result found", HttpStatus.NOT_FOUND);
        }
        Object componentValue = regeocode.get("addressComponent");
        Map<?, ?> component = componentValue instanceof Map<?, ?> map ? map : Map.of();
        return new AmapGeocodeResponse(
                text(regeocode.get("formatted_address")),
                text(component.get("province")),
                text(component.get("city")),
                text(component.get("district")),
                String.valueOf(longitude),
                String.valueOf(latitude)
        );
    }

    private Map<?, ?> get(String uri) {
        try {
            return restTemplate().getForObject(uri, Map.class);
        } catch (RestClientException exception) {
            throw new BusinessException("300002", "Amap request failed", HttpStatus.BAD_GATEWAY);
        }
    }

    private RestTemplate restTemplate() {
        PetEmarketProperties.Amap amap = properties.getAmap();
        return restTemplateBuilder
                .rootUri(amap.getBaseUrl())
                .setConnectTimeout(Duration.ofSeconds(amap.getTimeoutSeconds()))
                .setReadTimeout(Duration.ofSeconds(amap.getTimeoutSeconds()))
                .build();
    }

    private String apiKey() {
        String key = properties.getAmap().getApiKey();
        if (isBlank(key)) {
            throw new BusinessException("300003", "AMAP_API_KEY is not configured", HttpStatus.SERVICE_UNAVAILABLE);
        }
        return key.trim();
    }

    private void ensureSuccess(Map<?, ?> response) {
        if (response == null) {
            throw new BusinessException("300002", "Amap response is empty", HttpStatus.BAD_GATEWAY);
        }
        if (!"1".equals(text(response.get("status")))) {
            String info = text(response.get("info"));
            throw new BusinessException("300002", isBlank(info) ? "Amap request failed" : info, HttpStatus.BAD_GATEWAY);
        }
    }

    private AmapPoiResponse toPoi(Map<?, ?> poi) {
        String[] location = splitLocation(text(poi.get("location")));
        return new AmapPoiResponse(
                text(poi.get("id")),
                text(poi.get("name")),
                text(poi.get("type")),
                text(poi.get("typecode")),
                text(poi.get("address")),
                text(poi.get("pname")),
                text(poi.get("cityname")),
                text(poi.get("adname")),
                location[0],
                location[1],
                text(poi.get("tel")),
                parseDouble(poi.get("distance"))
        );
    }

    private String[] splitLocation(String location) {
        String[] parts = location.split(",", 2);
        if (parts.length != 2) {
            return new String[]{"", ""};
        }
        return new String[]{parts[0], parts[1]};
    }

    private Double parseDouble(Object value) {
        try {
            String text = text(value);
            return text.isBlank() ? null : Double.parseDouble(text);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private String text(Object value) {
        return value == null ? "" : value.toString();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
