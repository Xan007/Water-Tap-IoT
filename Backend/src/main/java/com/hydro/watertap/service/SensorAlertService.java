package com.hydro.watertap.service;

import com.hydro.watertap.model.entity.SensorAlertEntity;
import com.hydro.watertap.repository.SensorAlertRepository;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
public class SensorAlertService {

    private final SensorAlertRepository alertRepository;
    private final Sinks.Many<SensorAlertEntity> alertSink;

    public SensorAlertService(SensorAlertRepository alertRepository) {
        this.alertRepository = alertRepository;
        this.alertSink = Sinks.many().multicast().onBackpressureBuffer();
    }

    // Crear y emitir alerta
    public SensorAlertEntity createAlert(SensorAlertEntity alert) {
        alert.setActive(true);
        SensorAlertEntity saved = alertRepository.save(alert);
        alertSink.tryEmitNext(saved);
        return saved;
    }

    // Desactivar alerta y emitir evento
    public Optional<SensorAlertEntity> deactivateAlert(Long id) {
        return alertRepository.findById(id).map(alert -> {
            alert.setActive(false);
            SensorAlertEntity saved = alertRepository.save(alert);
            alertSink.tryEmitNext(saved);
            return saved;
        });
    }

    // Obtener alertas activas desde BD
    public List<SensorAlertEntity> getActiveAlerts() {
        return alertRepository.findByActiveTrue();
    }

    // Flujo reactivo: primero snapshot (una sola vez), luego stream en tiempo real
    public Flux<SensorAlertEntity> getAlertStreamWithSnapshot() {
        return Flux.defer(() -> Flux.concat(
                Flux.fromIterable(getActiveAlerts()), // snapshot inicial
                alertSink.asFlux()
        ));
    }
}
