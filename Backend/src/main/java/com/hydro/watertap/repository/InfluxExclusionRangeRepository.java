package com.hydro.watertap.repository;

import com.hydro.watertap.model.entity.InfluxExclusionRange;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface InfluxExclusionRangeRepository extends JpaRepository<InfluxExclusionRange, Long> {

    @Query("SELECT e FROM InfluxExclusionRange e WHERE e.sensorId IN :sensorIds AND e.endTime >= :from AND e.startTime <= :to")
    List<InfluxExclusionRange> findOverlapping(@Param("sensorIds") List<Integer> sensorIds,
                                               @Param("from") Instant from,
                                               @Param("to") Instant to);
}

