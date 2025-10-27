package com.hydro.watertap.controller;

import com.hydro.watertap.model.dto.DeleteRequest;
import com.hydro.watertap.model.dto.SensorRecordDTO;
import com.hydro.watertap.service.SensorDataService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.time.*;
import java.time.temporal.ChronoUnit;
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

    @GetMapping("/history/since")
    public List<SensorRecordDTO> getHistorySince(
            @RequestParam(name = "amount") int amount,
            @RequestParam(name = "unit") String unit,
            @RequestParam(name = "agg", required = false) String agg
    ) {
        if (amount <= 0) amount = 1;
        ChronoUnit chrono = parseUnit(unit);
        Instant to = Instant.now();
        Instant from = to.minus(amount, chrono);
        if (agg != null && !agg.isBlank()) {
            return sensorDataService.getAggregatedHistory(from, to, agg);
        }
        return sensorDataService.getHistory(from, to);
    }

    private ChronoUnit parseUnit(String unit) {
        if (unit == null) return ChronoUnit.HOURS;
        String u = unit.trim().toLowerCase();
        switch (u) {
            case "m":
            case "min":
            case "mins":
            case "minute":
            case "minutes":
            case "minuto":
            case "minutos":
                return ChronoUnit.MINUTES;
            case "h":
            case "hr":
            case "hour":
            case "hours":
            case "hora":
            case "horas":
                return ChronoUnit.HOURS;
            case "d":
            case "day":
            case "days":
            case "dia":
            case "dias":
                return ChronoUnit.DAYS;
            default:
                return ChronoUnit.HOURS;
        }
    }

    @PostMapping("/upload")
    public void uploadSensorData(@RequestBody List<SensorRecordDTO> records) {
        sensorDataService.saveSensorData(records);
    }

    @DeleteMapping("/data")
    public int deleteData(@RequestBody DeleteRequest req) {
        return sensorDataService.deleteData(
                req.getSensorIds(),
                req.getFrom(),
                req.getTo()
        );
    }
}
