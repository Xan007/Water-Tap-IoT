package com.hydro.watertap.model.entity;

import com.vladmihalcea.hibernate.type.json.JsonBinaryType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Type;

@Entity
@Table(name = "sensor_alerts")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SensorAlertEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Integer sensorId;

    @Column(nullable = false)
    private String description;

    @Column(nullable = false)
    private String severity;

    private Boolean active = true;
}
