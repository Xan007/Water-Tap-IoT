package com.hydro.watertap.model.dto;

import java.time.Instant;

public record SensorRecordDTO(
        Instant timestamp,
        Integer sensorId,
        Double ph,
        Double turbidity,
        Double conductivity,
        Double flowRate
) {
    public static SensorRecordDTO fromRaw(SensorRawRecord raw) {
        return new SensorRecordDTO(
                raw.timestamp(),
                raw.sensorId(),
                raw.metrics().getOrDefault("ph", null),
                raw.metrics().getOrDefault("turbidity", null),
                raw.metrics().getOrDefault("conductivity", null),
                raw.metrics().getOrDefault("flowRate", null)
        );
    }
}
