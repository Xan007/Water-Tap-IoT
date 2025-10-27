package com.hydro.watertap.service;

import com.hydro.watertap.model.dto.SensorRecordDTO;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

@Service
public class CsvReportService {

    private final SensorDataService sensorDataService;

    public CsvReportService(SensorDataService sensorDataService) {
        this.sensorDataService = sensorDataService;
    }

    /**
     * Genera CSV con dos secciones combinadas en un único archivo:
     * - Datos crudos: timestamp,sensorId,ph,turbidity,conductivity,flowRate
     * - Datos agregados por bucket (15m si rango <12h, 1h en caso contrario):
     *   bucketStart,sensorId,avgFlow,minFlow,maxFlow,avgPh,minPh,maxPh,avgTurb,minTurb,maxTurb,avgCond,minCond,maxCond
     */
    public byte[] generateCsv(Instant from, Instant to) {
        StringBuilder sb = new StringBuilder();

        // 1) Datos crudos
        List<SensorRecordDTO> raw = sensorDataService.getRawHistory(from, to);
        sb.append("# Datos crudos\n");
        sb.append("timestamp,sensorId,ph,turbidity,conductivity,flowRate\n");
        for (SensorRecordDTO r : raw) {
            sb.append(nz(r.timestamp() != null ? r.timestamp().toString() : null)).append(",")
              .append(nz(r.sensorId())).append(",")
              .append(nz(r.ph())).append(",")
              .append(nz(r.turbidity())).append(",")
              .append(nz(r.conductivity())).append(",")
              .append(nz(r.flowRate())).append("\n");
        }

        // 2) Datos agregados por bucket útil para Excel
        long minutes = Duration.between(from, to).toMinutes();
        int bucketMinutes = minutes < 12 * 60 ? 15 : 60;
        List<SensorRecordDTO> bucketed = sensorDataService.getRawHistoryAggregatedInMemory(from, to, Duration.ofMinutes(bucketMinutes));
        Map<String, Agg> acc = new LinkedHashMap<>(); // key sensorId|bucketStart
        long bucketMs = Duration.ofMinutes(bucketMinutes).toMillis();
        for (SensorRecordDTO r : bucketed) {
            if (r.sensorId() == null || r.timestamp() == null) continue;
            long b = (r.timestamp().toEpochMilli() / bucketMs) * bucketMs;
            String key = r.sensorId() + "|" + b;
            Agg a = acc.computeIfAbsent(key, k -> new Agg(r.sensorId(), b));
            if (r.flowRate() != null) a.flowStats.accept(r.flowRate());
            if (r.ph() != null) a.phStats.accept(r.ph());
            if (r.turbidity() != null) a.turbStats.accept(r.turbidity());
            if (r.conductivity() != null) a.condStats.accept(r.conductivity());
        }

        sb.append("\n# Agregado por ").append(bucketMinutes).append("m\n");
        sb.append("bucketStart,sensorId,avgFlow,minFlow,maxFlow,avgPh,minPh,maxPh,avgTurb,minTurb,maxTurb,avgCond,minCond,maxCond\n");
        for (Agg a : acc.values()) {
            sb.append(Instant.ofEpochMilli(a.bucketStart).toString()).append(",")
              .append(a.sensorId).append(",")
              .append(nz(a.flowStats.avg())).append(",").append(nz(a.flowStats.min())).append(",").append(nz(a.flowStats.max())).append(",")
              .append(nz(a.phStats.avg())).append(",").append(nz(a.phStats.min())).append(",").append(nz(a.phStats.max())).append(",")
              .append(nz(a.turbStats.avg())).append(",").append(nz(a.turbStats.min())).append(",").append(nz(a.turbStats.max())).append(",")
              .append(nz(a.condStats.avg())).append(",").append(nz(a.condStats.min())).append(",").append(nz(a.condStats.max())).append("\n");
        }

        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    private String nz(Object v) { return v == null ? "" : String.valueOf(v); }

    private static class Agg {
        final int sensorId; final long bucketStart;
        final Stats flowStats = new Stats();
        final Stats phStats = new Stats();
        final Stats turbStats = new Stats();
        final Stats condStats = new Stats();
        Agg(int sid, long b) { this.sensorId = sid; this.bucketStart = b; }
    }
    private static class Stats {
        double sum = 0; int n = 0; Double min = null; Double max = null;
        void accept(double v) { sum += v; n++; min = (min==null? v: Math.min(min, v)); max = (max==null? v: Math.max(max, v)); }
        Double avg() { return n>0 ? sum/n : null; }
        Double min() { return min; }
        Double max() { return max; }
    }
}

