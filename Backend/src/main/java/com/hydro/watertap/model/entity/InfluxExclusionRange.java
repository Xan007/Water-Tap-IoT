package com.hydro.watertap.model.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "influx_exclusions")
public class InfluxExclusionRange {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sensor_id", nullable = false)
    private Integer sensorId;

    @Column(name = "start_time", nullable = false)
    private Instant startTime;

    @Column(name = "end_time", nullable = false)
    private Instant endTime;

    public InfluxExclusionRange() {}

    public InfluxExclusionRange(Integer sensorId, Instant startTime, Instant endTime) {
        this.sensorId = sensorId;
        this.startTime = startTime;
        this.endTime = endTime;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getSensorId() { return sensorId; }
    public void setSensorId(Integer sensorId) { this.sensorId = sensorId; }

    public Instant getStartTime() { return startTime; }
    public void setStartTime(Instant startTime) { this.startTime = startTime; }

    public Instant getEndTime() { return endTime; }
    public void setEndTime(Instant endTime) { this.endTime = endTime; }
}

