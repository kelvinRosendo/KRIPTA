package com.kripta.exception;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

public final class ApiError {

    private ApiError() {
    }

    public static Map<String, Object> of(String error, String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", "error");
        body.put("error", error);
        body.put("message", message);
        return body;
    }
}
