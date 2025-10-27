package com.hydro.watertap.model.dto;

import java.time.Instant;
import java.util.List;

public class DeleteRequest {
    // measurement eliminado: por defecto será "water_sensors" en el servicio
    private List<Integer> sensorIds; // requerido al menos uno
    private Instant from; // opcional, si null -> EPOCH
    private Instant to;   // opcional, si null -> now

    public List<Integer> getSensorIds() { return sensorIds; }
    public void setSensorIds(List<Integer> sensorIds) { this.sensorIds = sensorIds; }

    public Instant getFrom() { return from; }
    public void setFrom(Instant from) { this.from = from; }

    public Instant getTo() { return to; }
    public void setTo(Instant to) { this.to = to; }
}
