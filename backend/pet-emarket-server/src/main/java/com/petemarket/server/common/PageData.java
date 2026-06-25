package com.petemarket.server.common;

import java.util.List;

public record PageData<T>(List<T> items) {
    public static <T> PageData<T> of(List<T> items) {
        return new PageData<>(items);
    }
}
