package com.hydro.watertap.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Map;

public class JsonUtils {
    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static Map<String, Object> safeParse(String content) {
        if (content == null) return null;
        try {
            return MAPPER.readValue(content, Map.class);
        } catch (Exception e) {
            // intentar limpiar texto no JSON (p.ej. bloque de código)
            String trimmed = content.trim();
            int start = trimmed.indexOf('{');
            int end = trimmed.lastIndexOf('}');
            if (start >= 0 && end > start) {
                try {
                    return MAPPER.readValue(trimmed.substring(start, end + 1), Map.class);
                } catch (JsonProcessingException ex) {
                    return null;
                }
            }
            return null;
        }
    }
}

