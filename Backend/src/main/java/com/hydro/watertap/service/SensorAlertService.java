package com.hydro.watertap.service;

import com.hydro.watertap.model.entity.SensorAlertEntity;
import com.hydro.watertap.repository.SensorAlertRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class SensorAlertService {

    private final SensorAlertRepository alertRepository;
    private final Sinks.Many<SensorAlertEntity> alertSink;

    @Value("${alerts.auto-resolve-minutes:0}")
    private int autoResolveMinutes;

    public SensorAlertService(SensorAlertRepository alertRepository) {
        this.alertRepository = alertRepository;
        this.alertSink = Sinks.many().multicast().onBackpressureBuffer();
    }

    // Crear y emitir alerta
    @Transactional
    public SensorAlertEntity createAlert(SensorAlertEntity alert) {
        alert.setActive(true);
        SensorAlertEntity saved = alertRepository.save(alert);
        alertSink.tryEmitNext(saved);
        return saved;
    }

    // Crear alerta solo si no existe activa con mismo sensorId+description+severity
    @Transactional
    public Optional<SensorAlertEntity> createAlertIfNotExists(SensorAlertEntity alert) {
        return alertRepository
                .findFirstBySensorIdAndDescriptionAndSeverityAndActiveTrue(alert.getSensorId(), alert.getDescription(), alert.getSeverity())
                .or(() -> Optional.of(createAlert(alert)));
    }

    // Crear o actualizar alerta por sensor: si existe activa para el sensor, actualizar la descripción/solución; si no, crearla
    @Transactional
    public SensorAlertEntity createOrUpdateAlertForSensor(SensorAlertEntity incoming) {
        Integer sid = incoming.getSensorId();
        if (sid != null) {
            List<SensorAlertEntity> existing = alertRepository.findBySensorIdAndActiveTrue(sid);
            if (!existing.isEmpty()) {
                SensorAlertEntity current = existing.get(0);
                current.setDescription(incoming.getDescription());
                current.setSeverity(incoming.getSeverity());
                current.setSolution(incoming.getSolution());
                SensorAlertEntity saved = alertRepository.save(current);
                alertSink.tryEmitNext(saved);
                return saved;
            }
        }
        return createAlert(incoming);
    }

    // Scheduler para auto-resolver alertas antiguas si se configura alerts.auto-resolve-minutes > 0
    @Scheduled(fixedRateString = "${alerts.auto-resolve-check-ms:60000}", initialDelay = 30000)
    @Transactional
    public void autoResolveOldAlerts() {
        if (autoResolveMinutes <= 0) return; // desactivado
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(autoResolveMinutes);
        List<SensorAlertEntity> oldActives = alertRepository.findByActiveTrueAndCreatedAtBefore(threshold);
        for (SensorAlertEntity a : oldActives) {
            a.setActive(false);
            SensorAlertEntity saved = alertRepository.save(a);
            alertSink.tryEmitNext(saved);
        }
    }

    // Desactivar alerta y emitir evento
    @Transactional
    public Optional<SensorAlertEntity> deactivateAlert(Long id) {
        return alertRepository.findById(id).map(alert -> {
            alert.setActive(false);
            SensorAlertEntity saved = alertRepository.save(alert);
            alertSink.tryEmitNext(saved);
            return saved;
        });
    }

    // Activar alerta y emitir evento
    @Transactional
    public Optional<SensorAlertEntity> activateAlert(Long id) {
        return alertRepository.findById(id).map(alert -> {
            alert.setActive(true);
            SensorAlertEntity saved = alertRepository.save(alert);
            alertSink.tryEmitNext(saved);
            return saved;
        });
    }

    // Eliminar alerta
    @Transactional
    public void deleteAlert(Long id) {
        alertRepository.deleteById(id);
    }

    public void removeAlert(Long id) { deleteAlert(id); }

    // Obtener alertas activas desde BD
    public List<SensorAlertEntity> getActiveAlerts() { return alertRepository.findByActiveTrue(); }

    // Flujo reactivo: snapshot + stream
    public Flux<SensorAlertEntity> getAlertStreamWithSnapshot() {
        return Flux.defer(() -> Flux.concat(
                Flux.fromIterable(getActiveAlerts()),
                alertSink.asFlux()
        ));
    }
}
