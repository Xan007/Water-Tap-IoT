package com.hydro.watertap.controller;

import com.hydro.watertap.model.dto.SensorRecordDTO;
import com.hydro.watertap.service.SensorDataService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/sensors")
@Tag(name = "Sensors", description = "Endpoints para datos de sensores")
public class SensorController {

    private final Flux<List<SensorRecordDTO>> sharedStream;
    private final SensorDataService sensorDataService;

    public SensorController(SensorDataService sensorDataService) {
        this.sensorDataService = sensorDataService;
        this.sharedStream = Flux.interval(Duration.ZERO, Duration.ofSeconds(15))
                .map(tick -> sensorDataService.getRecentSensorData(5))
                .replay(1)
                .refCount()
                .share();
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<List<SensorRecordDTO>> streamSensorData() {
        return sharedStream;
    }

    @GetMapping("/history")
    public List<SensorRecordDTO> getHistoryData(
            @RequestParam("from") Instant from,
            @RequestParam("to") Instant to
    ) {
        return sensorDataService.getHistory(from, to);
    }

    @PostMapping("/upload")
    public void uploadSensorData(@RequestBody List<SensorRecordDTO> records) {
        sensorDataService.saveSensorData(records);
    }
}
