package com.hydro.watertap.repository;

import com.hydro.watertap.model.entity.SensorAlertEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SensorAlertRepository extends JpaRepository<SensorAlertEntity, Long> {
    List<SensorAlertEntity> findByActiveTrue();
    List<SensorAlertEntity> findBySensorIdAndActiveTrue(Integer sensorId);
    Optional<SensorAlertEntity> findFirstBySensorIdAndDescriptionAndSeverityAndActiveTrue(Integer sensorId, String description, String severity);
    List<SensorAlertEntity> findByActiveTrueAndCreatedAtBefore(LocalDateTime threshold);
}
