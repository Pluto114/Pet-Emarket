package com.petemarket.server.media;

public record OssUploadResult(
        String objectKey,
        String url,
        String contentType,
        long size
) {
}
