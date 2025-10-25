package com.hydro.watertap.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.DayOfWeek;
import java.time.LocalTime;

@Entity
@Table(name = "ai_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiSettingsEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Activar/desactivar IA
    @Column(nullable = false)
    private boolean aiEnabled = true;

    // Horario laboral simple (mismo para todos los días) - se puede extender luego a reglas por día
    private LocalTime workStart; // hora inicio cuando hay gente
    private LocalTime workEnd;   // hora fin cuando hay gente

    // Días hábiles: si false, se considera que no hay gente
    private boolean monday = true;
    private boolean tuesday = true;
    private boolean wednesday = true;
    private boolean thursday = true;
    private boolean friday = true;
    private boolean saturday = false;
    private boolean sunday = false;
}

