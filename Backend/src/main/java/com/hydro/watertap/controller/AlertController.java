package com.hydro.watertap.controller;

import com.hydro.watertap.model.entity.SensorAlertEntity;
import com.hydro.watertap.service.SensorAlertService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.List;

@RestController
@RequestMapping("/alerts")
@Tag(name = "Alerts", description = "Endpoints para alertas de sensores")
public class AlertController {

    private final SensorAlertService alertService;

    public AlertController(SensorAlertService alertService) {
        this.alertService = alertService;
    }

    // SSE con snapshot inicial + stream
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<SensorAlertEntity> streamAlerts() {
        return alertService.getAlertStreamWithSnapshot();
    }

    @GetMapping
    public List<SensorAlertEntity> getActive() { return alertService.getActiveAlerts(); }

    @PostMapping
    public SensorAlertEntity createAlert(@RequestBody SensorAlertEntity alert) {
        alert.setId(null);
        return alertService.createAlert(alert);
    }

    // Desactivar alerta
    @PostMapping("/{id}/deactivate")
    public void deactivateAlert(@PathVariable Long id) {
        alertService.deactivateAlert(id);
    }

    // Borrar alerta
    @DeleteMapping("/{id}")
    public void deleteAlert(@PathVariable Long id) {
        alertService.removeAlert(id);
    }
}
