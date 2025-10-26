package com.hydro.watertap.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hydro.watertap.model.dto.SensorRecordDTO;
import com.hydro.watertap.model.entity.SensorAlertEntity;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.*;

@Service
public class AiAnomalyService {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final Logger log = LoggerFactory.getLogger(AiAnomalyService.class);

    private final ChatModel chatModel;
    private final SensorDataService sensorDataService;
    private final SensorAlertService alertService;
    private final AiSettingsService settingsService;

    @Value("${ai.recent.minutes:10}")
    private int recentMinutes;

    public AiAnomalyService(ChatModel chatModel,
                            SensorDataService sensorDataService,
                            SensorAlertService alertService,
                            AiSettingsService settingsService) {
        this.chatModel = chatModel;
        this.sensorDataService = sensorDataService;
        this.alertService = alertService;
        this.settingsService = settingsService;
    }

    // Para pruebas: ejecutar cada 1 minuto
    @Scheduled(fixedRateString = "${ai.check.rate-ms:60000}", initialDelayString = "${ai.check.initial-delay-ms:30000}")
    public void runAiCheck() {
        try {
            if (!settingsService.isAiEnabled()) return;

            ZoneId bogota = ZoneId.of("America/Bogota");
            LocalDateTime nowLocal = LocalDateTime.now(bogota);
            boolean workTime = settingsService.isWorkTime(nowLocal);

            // Obtener últimos 10 minutos de datos crudos
            List<SensorRecordDTO> last10min = sensorDataService.getRecentSensorData(recentMinutes);
            // Obtener últimas ~6 horas agregadas por hora para contexto
            Instant nowInstant = Instant.now();
            Instant from = nowInstant.minusSeconds(6 * 3600);
            Instant to = nowInstant;
            List<SensorRecordDTO> lastHours = sensorDataService.getAggregatedHistory(from, to, "1h");

            if (last10min.isEmpty() && lastHours.isEmpty()) return;

            String summary = buildCompactJson(last10min, lastHours, workTime);

            String prompt = buildPrompt(summary);

            log.info("AI Prompt: {}", prompt);

            String content = chatModel.call(prompt);



            Map<String, Object> parsed = parseJson(content);

            log.info("AI Response: {}", parsed);
            if (parsed == null) return;

            Map<Integer, SensorAlertEntity> bestBySensor = dedupeAlerts(parsed.get("alerts"));
            for (SensorAlertEntity entity : bestBySensor.values()) {
                alertService.createOrUpdateAlertForSensor(entity);
            }
        } catch (Exception e) {
            log.warn("AI anomaly check falló: {}", e.getMessage());
        }
    }

    private String buildPrompt(String summary) {
        return "Eres analista de consumo de agua. Responde SIEMPRE en español. Responde SOLO en JSON exacto con este esquema: {\\n" +
                "  \\\"alerts\\\": [\\n" +
                "    {\\n" +
                "      \\\"sensorId\\\": entero,\\n" +
                "      \\\"severity\\\": uno de [\\\\\\\"LOW\\\\\\\", \\\\\\\"MEDIUM\\\\\\\", \\\\\\\"HIGH\\\\\\\"],\\n" +
                "      \\\"description\\\": string concisa y específica (incluye magnitud/criterio y fecha/hora o intervalo ISO SIN fracciones de segundo, p.ej. \\\"flujo ~0.50 L/min entre 2025-10-25T05:10:00Z y 2025-10-25T05:25:00Z; pH~7.00; turbidez~0.40; conductividad~250.00\\\"),\\n" +
                "      \\\"solution\\\": string opcional SOLO si el problema es de flujo (p.ej. \\\"cerrar llave de paso y revisar posible fuga\\\")\\n" +
                "    }\\n" +
                "  ]\\n" +
                "}.\\n" +
                "Reglas urgentes (leer con atención):\\n" +
                "1) Usa EXCLUSIVAMENTE el array last10min para decidir alertas. Si last10min está vacío o no contiene lecturas válidas, responde exactamente: {\\\"alerts\\\": []}.\\n" +
                "2) IGNORA lastHours para la generación de alertas (solo contexto analítico).\\n" +
                "3) Dentro de last10min, da mayor peso a los puntos más recientes (1–3 min > 4–10 min).\\n" +
                "4) Interpreta workTime:\\n" +
                "   • workTime=true → horario laboral; consumo moderado esperado; alerta solo si flujo en last10min es anormalmente alto o sostenido DENTRO de esos 10 minutos. NUNCA uses 'fuera de horario' aquí.\\n" +
                "   • workTime=false → fuera de horario; consumo debe ser muy bajo; flujo alto o sostenido es sospechoso y puedes indicar 'fuera de horario'.\\n" +
                "5) PRIORIDAD entre variables: **no** priorizar automáticamente el flujo. Los parámetros de calidad (pH, turbidez, conductividad) deben evaluarse con igual o mayor peso que el flujo. Si CUALQUIERA de pH/turbidez/conductividad está fuera de los umbrales, GENERA alerta aunque el flujo sea bajo (salvo que la lectura sea inválida).\\n" +
                "6) Umbrales sugeridos para un lavamanos (ajustables):\\n" +
                "   • pH: normal 6.5–8.5. Fuera de rango: pH < 6.5 o pH > 8.5.\\n" +
                "   • Turbidez (NTU): normal < 1.0. Fuera de rango: >= 1.0.\\n" +
                "   • Conductividad (µS/cm): normal < 500. Fuera de rango: >= 500.\\n" +
                "   • Flujo (L/min) para lavamanos: típico bajo; considera alerta si flujo medio en last10min supera un umbral definido por tu contexto (p. ej. > 0.8 L/min sostenido en los últimos minutos) — pero recuerda que un problema de calidad debe pesar más que un flujo moderado.\\n" +
                "7) Severidad (reglas combinadas):\\n" +
                "   • HIGH: alguna variable de calidad fuera de rango de forma clara (pH muy bajo/alto o turbidez >= 2.0 o conductividad >> 500) o combinación de flujo alto + calidad fuera de rango en last10min.\\n" +
                "   • MEDIUM: calidad ligeramente fuera de rango (pH marginal, turbidez >=1.0 y <2.0, conductividad alrededor de límite) o flujo moderado-alto sostenido en last10min sin fuerte evidencia de problema de calidad.\\n" +
                "   • LOW: anomalía leve en alguno de los parámetros que no representa riesgo inmediato pero merece seguimiento.\\n" +
                "8) Lecturas INVÁLIDAS se IGNORAN: pH <= 0, flowRate <= 0, todos campos = 0, sensorId absurdo (>1_000_000_000). Si tras descartar inválidos no hay lecturas válidas en last10min, aplica regla (1).\\n" +
                "9) La description NUNCA debe incluir el número del sensor ni mencionar errores/configuraciones o texto sobre datos raros. Describir SOLO comportamiento del agua con magnitud redondeada a 2 decimales y timestamps ISO SIN fracciones.\\n" +
                "10) PROHIBIDO en description: expresiones de duración en palabras (\\\"durante 5 min\\\", etc.). Usa SOLO intervalos/timestamps ISO.\\n" +
                "11) No inventes datos. No incluyas soluciones en description; usa solution solo si aplica y únicamente para problemas de flujo.\\n" +
                "12) Unica alerta por sensorId: si hay múltiples lecturas válidas en last10min para el mismo sensor, sintetiza una alerta que represente el patrón usando la mayor severidad y un intervalo ISO que cubra las lecturas relevantes. Incluye en la description, además del flujo, los valores relevantes de pH, turbidez y conductividad redondeados a 2 decimales si ayudan a justificar la alerta.\\n" +
                "13) Responde EXACTAMENTE con JSON válido y NADA más.\\n" +
                "Ejemplo correcto de description:\\n" +
                "\\\"flujo ~0.95 L/min entre 2025-10-25T08:16:00Z y 2025-10-25T08:20:00Z; pH~5.90; turbidez~1.50; conductividad~620.00\\\"\\n" +
                "Datos recientes y contexto a analizar (contiene workTime, generatedAt, last10min, lastHours):\\n" + summary;
    }




    // Parsea y deduplica alertas por sensorId, eligiendo la de mayor severidad; en empate, la que tenga solución
    private Map<Integer, SensorAlertEntity> dedupeAlerts(Object alertsObj) {
        Map<Integer, SensorAlertEntity> bestBySensor = new LinkedHashMap<>();
        if (!(alertsObj instanceof List<?> alerts)) return bestBySensor;
        for (Object a : alerts) {
            if (!(a instanceof Map<?, ?> m)) continue;
            Integer sid = toInt(m.get("sensorId"));
            if (sid == null) continue;
            String severity = strOrDefault(m.get("severity"), "MEDIUM");
            String description = strOrDefault(m.get("description"), "Anomalía detectada");
            String solution = strOrDefault(m.get("solution"), null);

            SensorAlertEntity candidate = SensorAlertEntity.builder()
                    .sensorId(sid)
                    .severity(severity)
                    .description(description)
                    .solution(solution)
                    .active(true)
                    .build();

            SensorAlertEntity current = bestBySensor.get(sid);
            if (current == null) {
                bestBySensor.put(sid, candidate);
            } else {
                int curRank = severityRank(current.getSeverity());
                int newRank = severityRank(severity);
                if (newRank > curRank) {
                    bestBySensor.put(sid, candidate);
                } else if (newRank == curRank) {
                    boolean curHasSol = current.getSolution() != null && !current.getSolution().isBlank();
                    boolean newHasSol = solution != null && !solution.isBlank();
                    if (!curHasSol && newHasSol) bestBySensor.put(sid, candidate);
                }
            }
        }
        return bestBySensor;
    }

    private Integer toInt(Object o) {
        if (o instanceof Number n) return n.intValue();
        if (o instanceof String s) {
            try { return Integer.parseInt(s); } catch (NumberFormatException ignored) {}
        }
        return null;
    }

    private String strOrDefault(Object o, String def) {
        return o == null ? def : String.valueOf(o);
    }

    private int severityRank(String s) {
        if (s == null) return 2; // MEDIUM por defecto
        String v = s.trim().toUpperCase(Locale.ROOT);
        if (v.contains("HIGH") || v.contains("ALTA")) return 3;
        if (v.contains("MEDIUM") || v.contains("MEDIA")) return 2;
        if (v.contains("LOW") || v.contains("BAJA")) return 1;
        return 2;
    }

    private Map<String, Object> parseJson(String content) {
        if (content == null) return null;
        try {
            return MAPPER.readValue(content, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            String trimmed = content.trim();
            int start = trimmed.indexOf('{');
            int end = trimmed.lastIndexOf('}');
            if (start >= 0 && end > start) {
                try {
                    return MAPPER.readValue(trimmed.substring(start, end + 1), new TypeReference<Map<String, Object>>() {});
                } catch (JsonProcessingException ex) {
                    return null;
                }
            }
            return null;
        }
    }

    private String buildCompactJson(List<SensorRecordDTO> last10min, List<SensorRecordDTO> lastHours, boolean workTime) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\n  \"workTime\": ").append(workTime).append(",\n");

        // Delimitar ventana temporal de los últimos N minutos (min y max timestamp observados)
        Instant minTs = null, maxTs = null;

        // Agregar últimos 10 minutos por sensor con estadísticos
        Map<Integer, Stats> map = new LinkedHashMap<>();
        for (SensorRecordDTO r : last10min) {
            if (r.sensorId() == null) continue;
            Stats s = map.computeIfAbsent(r.sensorId(), Stats::new);
            s.update10m(r);
            if (r.timestamp() != null) {
                if (minTs == null || r.timestamp().isBefore(minTs)) minTs = r.timestamp();
                if (maxTs == null || r.timestamp().isAfter(maxTs)) maxTs = r.timestamp();
            }
        }
        if (minTs != null) sb.append("  \"windowStart\": \"").append(minTs).append("\",\n");
        if (maxTs != null) sb.append("  \"windowEnd\": \"").append(maxTs).append("\",\n");
        sb.append("  \"generatedAt\": \"").append(Instant.now()).append("\",\n");
        sb.append("  \"last10min\": [");
        int idx = 0;
        for (Stats s : map.values()) {
            if (idx++ > 0) sb.append(",");
            // Flow
            Double avgFlow = s.flowCount > 0 ? (s.flowSum / s.flowCount) : null;
            Double varFlow = s.flowCount > 0 ? (s.flowSumSq / s.flowCount) - (avgFlow == null ? 0.0 : avgFlow * avgFlow) : null;
            Double stdFlow = varFlow == null ? null : Math.sqrt(Math.max(0.0, varFlow));
            Double minFlow = s.flowMin == Double.POSITIVE_INFINITY ? null : s.flowMin;
            Double maxFlow = s.flowMax == Double.NEGATIVE_INFINITY ? null : s.flowMax;
            // pH
            Double avgPh = s.phCount > 0 ? (s.phSum / s.phCount) : null;
            Double varPh = s.phCount > 0 ? (s.phSumSq / s.phCount) - (avgPh == null ? 0.0 : avgPh * avgPh) : null;
            Double stdPh = varPh == null ? null : Math.sqrt(Math.max(0.0, varPh));
            Double minPh = s.phMin == Double.POSITIVE_INFINITY ? null : s.phMin;
            Double maxPh = s.phMax == Double.NEGATIVE_INFINITY ? null : s.phMax;
            // Turbidez
            Double avgTurb = s.turbCount > 0 ? (s.turbSum / s.turbCount) : null;
            Double varTurb = s.turbCount > 0 ? (s.turbSumSq / s.turbCount) - (avgTurb == null ? 0.0 : avgTurb * avgTurb) : null;
            Double stdTurb = varTurb == null ? null : Math.sqrt(Math.max(0.0, varTurb));
            Double minTurb = s.turbMin == Double.POSITIVE_INFINITY ? null : s.turbMin;
            Double maxTurb = s.turbMax == Double.NEGATIVE_INFINITY ? null : s.turbMax;
            // Conductividad
            Double avgCond = s.condCount > 0 ? (s.condSum / s.condCount) : null;
            Double varCond = s.condCount > 0 ? (s.condSumSq / s.condCount) - (avgCond == null ? 0.0 : avgCond * avgCond) : null;
            Double stdCond = varCond == null ? null : Math.sqrt(Math.max(0.0, varCond));
            Double minCond = s.condMin == Double.POSITIVE_INFINITY ? null : s.condMin;
            Double maxCond = s.condMax == Double.NEGATIVE_INFINITY ? null : s.condMax;

            sb.append("{\"sensorId\":").append(s.sensorId)
              .append(",\"firstTs\":\"").append(s.firstTs == null ? "" : s.firstTs).append("\"")
              .append(",\"lastTs\":\"").append(s.lastTs == null ? "" : s.lastTs).append("\"")
              .append(",\"count\":").append(s.flowCount)
              .append(",\"activeMin\":").append(s.activeMin)
              .append(",\"lastFlow\":").append(s.lastFlow)
              .append(",\"avgFlowRate\":").append(avgFlow == null ? "null" : avgFlow)
              .append(",\"stdFlowRate\":").append(stdFlow == null ? "null" : stdFlow)
              .append(",\"minFlowRate\":").append(minFlow == null ? "null" : minFlow)
              .append(",\"maxFlowRate\":").append(maxFlow == null ? "null" : maxFlow)
              .append(",\"avgPh\":").append(avgPh == null ? "null" : avgPh)
              .append(",\"stdPh\":").append(stdPh == null ? "null" : stdPh)
              .append(",\"minPh\":").append(minPh == null ? "null" : minPh)
              .append(",\"maxPh\":").append(maxPh == null ? "null" : maxPh)
              .append(",\"avgTurbidity\":").append(avgTurb == null ? "null" : avgTurb)
              .append(",\"stdTurbidity\":").append(stdTurb == null ? "null" : stdTurb)
              .append(",\"minTurbidity\":").append(minTurb == null ? "null" : minTurb)
              .append(",\"maxTurbidity\":").append(maxTurb == null ? "null" : maxTurb)
              .append(",\"avgConductivity\":").append(avgCond == null ? "null" : avgCond)
              .append(",\"stdConductivity\":").append(stdCond == null ? "null" : stdCond)
              .append(",\"minConductivity\":").append(minCond == null ? "null" : minCond)
              .append(",\"maxConductivity\":").append(maxCond == null ? "null" : maxCond)
              .append("}");
        }
        sb.append("],\n  \"lastHours\": [");
        for (int i = 0; i < lastHours.size(); i++) {
            SensorRecordDTO r = lastHours.get(i);
            sb.append(toObj(r));
            if (i < lastHours.size() - 1) sb.append(",");
        }
        sb.append("]\n}");
        return sb.toString();
    }

    private String toObj(SensorRecordDTO r) {
        return "{\"t\":\"" + r.timestamp() + "\"," +
                "\"sensorId\":" + r.sensorId() + "," +
                "\"flowRate\":" + (r.flowRate() == null ? "null" : r.flowRate()) + "," +
                "\"ph\":" + (r.ph() == null ? "null" : r.ph()) + "," +
                "\"turbidity\":" + (r.turbidity() == null ? "null" : r.turbidity()) + "," +
                "\"conductivity\":" + (r.conductivity() == null ? "null" : r.conductivity()) +
                "}";
    }

    private static class Stats {
        final int sensorId;
        // 10 minutos
        double lastFlow = 0.0;
        Instant lastTs = Instant.EPOCH;
        Instant firstTs = null;
        double flowSum = 0.0; int flowCount = 0; double max10m = Double.NEGATIVE_INFINITY; double avg10m = 0.0;
        int activeMin = 0; // minutos con flujo > 0.1
        double phSum = 0.0; int phCount = 0;
        double turbSum = 0.0; int turbCount = 0;
        double condSum = 0.0; int condCount = 0;
        // 6 horas agregadas
        double h6FlowSum = 0.0; int h6Count = 0; double h6Max = Double.NEGATIVE_INFINITY;

        // Para min, max y desviación estándar en 10 minutos
        double flowMin = Double.POSITIVE_INFINITY; double flowMax = Double.NEGATIVE_INFINITY; double flowSumSq = 0.0;
        double phMin = Double.POSITIVE_INFINITY; double phMax = Double.NEGATIVE_INFINITY; double phSumSq = 0.0;
        double turbMin = Double.POSITIVE_INFINITY; double turbMax = Double.NEGATIVE_INFINITY; double turbSumSq = 0.0;
        double condMin = Double.POSITIVE_INFINITY; double condMax = Double.NEGATIVE_INFINITY; double condSumSq = 0.0;

        Stats(int id) { this.sensorId = id; }

        void update10m(SensorRecordDTO r) {
            Instant ts = r.timestamp();
            if (ts != null && ts.isAfter(lastTs)) {
                lastTs = ts;
                if (r.flowRate() != null) lastFlow = r.flowRate();
            }
            if (ts != null && (firstTs == null || ts.isBefore(firstTs))) firstTs = ts;
            if (r.flowRate() != null) {
                double f = r.flowRate();
                flowSum += f; flowCount++; flowSumSq += f * f;
                if (f > max10m) max10m = f;
                if (f > flowMax) flowMax = f;
                if (f < flowMin) flowMin = f;
                if (f > 0.1) activeMin++;
            }
            if (r.ph() != null) { double v = r.ph(); phSum += v; phCount++; phSumSq += v * v; if (v > phMax) phMax = v; if (v < phMin) phMin = v; }
            if (r.turbidity() != null) { double v = r.turbidity(); turbSum += v; turbCount++; turbSumSq += v * v; if (v > turbMax) turbMax = v; if (v < turbMin) turbMin = v; }
            if (r.conductivity() != null) { double v = r.conductivity(); condSum += v; condCount++; condSumSq += v * v; if (v > condMax) condMax = v; if (v < condMin) condMin = v; }
            if (flowCount > 0) avg10m = flowSum / flowCount;
        }

        void update6h(SensorRecordDTO r) {
            if (r.flowRate() != null) {
                double f = r.flowRate();
                h6FlowSum += f; h6Count++;
                if (f > h6Max) h6Max = f;
            }
        }
    }
}
