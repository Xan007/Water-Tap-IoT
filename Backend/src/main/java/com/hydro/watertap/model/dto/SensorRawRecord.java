package com.hydro.watertap.model.dto;

import java.time.Instant;
import java.util.Map;

public record SensorRawRecord(
        Instant timestamp,
        int sensorId,
        Map<String, Double> metrics
) {}
