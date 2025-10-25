package com.hydro.watertap.model.entity;

import com.vladmihalcea.hibernate.type.json.JsonBinaryType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.Type;

import java.time.LocalDateTime;

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

    @Builder.Default
    private Boolean active = true;

    // Sugerencia de solución cuando aplique (p.ej. problemas de flujo)
    private String solution;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
