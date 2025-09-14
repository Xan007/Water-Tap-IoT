package com.hydro.watertap.repository;

import com.hydro.watertap.model.entity.SensorAlertEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SensorAlertRepository extends JpaRepository<SensorAlertEntity, Long> {
    List<SensorAlertEntity> findByActiveTrue();
    List<SensorAlertEntity> findBySensorIdAndActiveTrue(Integer sensorId);
}
