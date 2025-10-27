package com.hydro.watertap.service;

import com.hydro.watertap.model.dto.SensorRecordDTO;
import com.lowagie.text.*;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.List;

@Service
public class PdfReportService {

    private static final Logger log = LoggerFactory.getLogger(PdfReportService.class);

    private final SensorDataService sensorDataService;
    private static final ZoneId BOGOTA = ZoneId.of("America/Bogota");
    private static final DateTimeFormatter DAY_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd").withZone(BOGOTA);
    private static final DateTimeFormatter HOUR_FMT = DateTimeFormatter.ofPattern("HH:mm").withZone(BOGOTA);
    private static final java.util.Locale ES_CO = new java.util.Locale("es","CO");
    private static final DateTimeFormatter FRIENDLY_DATE = DateTimeFormatter.ofPattern("d MMM yyyy", ES_CO).withZone(BOGOTA);
    private static final DateTimeFormatter FRIENDLY_TIME = DateTimeFormatter.ofPattern("HH:mm", ES_CO).withZone(BOGOTA);
    private static final DateTimeFormatter FRIENDLY_STAMP = DateTimeFormatter.ofPattern("d MMM yyyy, HH:mm", ES_CO).withZone(BOGOTA);

    public PdfReportService(SensorDataService sensorDataService) {
        this.sensorDataService = sensorDataService;
    }

    public byte[] generateReport(Instant from, Instant to, String ignored) {
        long days = ChronoUnit.DAYS.between(from, to);
        long minutes = ChronoUnit.MINUTES.between(from, to);
        int bucketMinutes = minutes < 12 * 60 ? 15 : 60;

        List<SensorRecordDTO> input;
        if (days > 3) {
            List<SensorRecordDTO> tenMin = sensorDataService.getRawHistoryAggregatedInMemory(from, to, Duration.ofMinutes(10));
            input = tenMin;
            bucketMinutes = 60; // consolidaremos por hora en el PDF
        } else {
            input = sensorDataService.getRawHistory(from, to);
        }

        Map<Integer, List<BucketStat>> statsBySensor = aggregateByBucket(input, bucketMinutes);

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Document doc = new Document(PageSize.A4, 36, 36, 36, 36);
            PdfWriter.getInstance(doc, baos);
            doc.open();

            String aggLabel = bucketMinutes + "m";
            String period = friendlyRange(from, to);

            Paragraph title = new Paragraph("WaterTap | Reporte de consumo y calidad del agua", new Font(Font.HELVETICA, 18, Font.BOLD, new Color(10, 94, 168)));
            title.setAlignment(Element.ALIGN_CENTER);
            doc.add(title);
            Paragraph meta = new Paragraph(
                    "Periodo: " + period +
                    "\nAgregación: " + aggLabel +
                    "\nGenerado: " + FRIENDLY_STAMP.format(Instant.now()),
                    new Font(Font.HELVETICA, 9)
            );
            meta.setAlignment(Element.ALIGN_CENTER);
            meta.setSpacingAfter(6f);
            doc.add(meta);

            if (statsBySensor.isEmpty()) {
                Paragraph empty = new Paragraph("No hay datos para el rango solicitado.", new Font(Font.HELVETICA, 11));
                empty.setAlignment(Element.ALIGN_CENTER);
                doc.add(empty);
                doc.close();
                return baos.toByteArray();
            }

            int processed = 0;
            int total = statsBySensor.size();
            for (Map.Entry<Integer, List<BucketStat>> e : statsBySensor.entrySet()) {
                Integer sensorId = e.getKey();
                List<BucketStat> rows = e.getValue();

                Paragraph header = new Paragraph("Sensor #" + sensorId, new Font(Font.HELVETICA, 13, Font.BOLD, new Color(10, 94, 168)));
                header.setSpacingBefore(4f);
                header.setSpacingAfter(4f);
                doc.add(header);

                PdfPTable table = buildBucketStatsTable(rows);
                table.setSpacingAfter(4f);
                doc.add(table);

                // Resumen estadístico por sensor
                Paragraph sumHeader = new Paragraph("Resumen estadístico", new Font(Font.HELVETICA, 11, Font.BOLD));
                sumHeader.setSpacingBefore(2f);
                sumHeader.setSpacingAfter(2f);
                doc.add(sumHeader);
                PdfPTable summary = buildSummaryTable(rows, bucketMinutes);
                summary.setSpacingAfter(8f);
                doc.add(summary);

                processed++;
                if (processed < total) doc.newPage();
            }

            doc.close();
            return baos.toByteArray();
        } catch (Exception ex) {
            log.warn("Fallo al generar PDF: {}", ex.getMessage());
            return ("No se pudo generar el PDF: " + ex.getMessage()).getBytes();
        }
    }

    private String friendlyRange(Instant from, Instant to) {
        String d1 = FRIENDLY_DATE.format(from);
        String d2 = FRIENDLY_DATE.format(to);
        String t1 = FRIENDLY_TIME.format(from);
        String t2 = FRIENDLY_TIME.format(to);
        if (d1.equals(d2)) {
            return d1 + ", " + t1 + " – " + t2;
        }
        return d1 + " " + t1 + " – " + d2 + " " + t2;
    }

    private Map<Integer, List<BucketStat>> aggregateByBucket(List<SensorRecordDTO> input, int bucketMinutes) {
        long bucketMs = Duration.ofMinutes(bucketMinutes).toMillis();
        Map<String, BucketAccum> map = new LinkedHashMap<>(); // key = sensorId|bucketStartMs
        for (SensorRecordDTO r : input) {
            if (r.sensorId() == null || r.timestamp() == null) continue;
            long t = r.timestamp().toEpochMilli();
            long b = (t / bucketMs) * bucketMs;
            String key = r.sensorId() + "|" + b;
            BucketAccum acc = map.computeIfAbsent(key, k -> new BucketAccum(r.sensorId(), b));
            acc.accept(r);
        }
        Map<Integer, List<BucketStat>> out = new LinkedHashMap<>();
        for (BucketAccum acc : map.values()) {
            BucketStat s = acc.toStat();
            out.computeIfAbsent(s.sensorId, k -> new ArrayList<>()).add(s);
        }
        for (List<BucketStat> list : out.values()) list.sort(Comparator.comparing(bs -> bs.bucketStart));
        return out;
    }

    private PdfPTable buildBucketStatsTable(List<BucketStat> rows) {
        // 14 columnas: Día, Hora, (Flujo Avg,Min,Max), (pH Avg,Min,Max), (Turbidez Avg,Min,Max), (Conductividad Avg,Min,Max)
        PdfPTable table = new PdfPTable(14);
        table.setWidthPercentage(100);
        try {
            table.setWidths(new float[]{2.5f, 1.5f, 1.1f, 1.1f, 1.1f, 1.1f, 1.1f, 1.1f, 1.2f, 1.2f, 1.2f, 1.6f, 1.6f, 1.6f});
        } catch (DocumentException ignored) {}

        // Encabezado fila 1 (grupos)
        addHeaderSpan(table, "Día", 1);
        addHeaderSpan(table, "Hora", 1);
        addHeaderSpan(table, "Flujo (L/min)", 3);
        addHeaderSpan(table, "pH", 3);
        addHeaderSpan(table, "Turbidez (NTU)", 3);
        addHeaderSpan(table, "Conductividad (µS/cm)", 3);

        // Encabezado fila 2 (subcolumnas) — agregar dos celdas vacías para alinear Día y Hora
        addHeader(table, "");
        addHeader(table, "");
        addHeader(table, "Avg"); addHeader(table, "Min"); addHeader(table, "Max");
        addHeader(table, "Avg"); addHeader(table, "Min"); addHeader(table, "Max");
        addHeader(table, "Avg"); addHeader(table, "Min"); addHeader(table, "Max");
        addHeader(table, "Avg"); addHeader(table, "Min"); addHeader(table, "Max");

        table.setHeaderRows(2);

        // Cuerpo con zebra striping
        boolean zebra = false;
        for (BucketStat r : rows) {
            Color bg = zebra ? new Color(250, 252, 255) : Color.WHITE;
            addBody(table, DAY_FMT.format(r.bucketStart), Element.ALIGN_LEFT, bg);
            addBody(table, HOUR_FMT.format(r.bucketStart), Element.ALIGN_LEFT, bg);
            addBody(table, fmtDouble(r.avgFlow), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.minFlow), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.maxFlow), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.avgPh), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.minPh), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.maxPh), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.avgTurb), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.minTurb), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.maxTurb), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.avgCond), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.minCond), Element.ALIGN_RIGHT, bg);
            addBody(table, fmtDouble(r.maxCond), Element.ALIGN_RIGHT, bg);
            zebra = !zebra;
        }
        return table;
    }

    private PdfPTable buildSummaryTable(List<BucketStat> rows, int bucketMinutes) {
        PdfPTable t = new PdfPTable(2);
        t.setWidthPercentage(80);
        try { t.setWidths(new float[]{2.2f, 4.8f}); } catch (DocumentException ignored) {}

        Instant first = rows.get(0).bucketStart;
        Instant last = rows.get(rows.size() - 1).bucketStart.plus(Duration.ofMinutes(bucketMinutes));
        int n = rows.size();

        Double avgFlow = mean(rows, r -> r.avgFlow);
        Double minFlow = min(rows, r -> r.minFlow);
        Double maxFlow = max(rows, r -> r.maxFlow);

        Double avgPh = mean(rows, r -> r.avgPh);
        Double minPh = min(rows, r -> r.minPh);
        Double maxPh = max(rows, r -> r.maxPh);

        Double avgT = mean(rows, r -> r.avgTurb);
        Double minT = min(rows, r -> r.minTurb);
        Double maxT = max(rows, r -> r.maxTurb);

        Double avgC = mean(rows, r -> r.avgCond);
        Double minC = min(rows, r -> r.minCond);
        Double maxC = max(rows, r -> r.maxCond);

        addKV(t, "Intervalos analizados", n + " (" + bucketMinutes + " min)");
        addKV(t, "Cobertura", friendlyRange(first, last));
        addKV(t, "Flujo (L/min)", "Promedio: " + fmtDouble(avgFlow) + "  |  Min: " + fmtDouble(minFlow) + "  |  Max: " + fmtDouble(maxFlow));
        addKV(t, "pH", "Promedio: " + fmtDouble(avgPh) + "  |  Min: " + fmtDouble(minPh) + "  |  Max: " + fmtDouble(maxPh));
        addKV(t, "Turbidez (NTU)", "Promedio: " + fmtDouble(avgT) + "  |  Min: " + fmtDouble(minT) + "  |  Max: " + fmtDouble(maxT));
        addKV(t, "Conductividad (µS/cm)", "Promedio: " + fmtDouble(avgC) + "  |  Min: " + fmtDouble(minC) + "  |  Max: " + fmtDouble(maxC));

        return t;
    }

    private interface ToDouble {
        Double get(BucketStat r);
    }
    private Double mean(List<BucketStat> rows, ToDouble f) {
        double s = 0; int c = 0;
        for (BucketStat r : rows) { Double v = f.get(r); if (v != null) { s += v; c++; } }
        return c == 0 ? null : s / c;
    }
    private Double min(List<BucketStat> rows, ToDouble f) {
        Double m = null;
        for (BucketStat r : rows) { Double v = f.get(r); if (v != null) m = (m == null) ? v : Math.min(m, v); }
        return m;
    }
    private Double max(List<BucketStat> rows, ToDouble f) {
        Double m = null;
        for (BucketStat r : rows) { Double v = f.get(r); if (v != null) m = (m == null) ? v : Math.max(m, v); }
        return m;
    }

    private void addKV(PdfPTable t, String key, String val) {
        PdfPCell k = new PdfPCell(new Phrase(key, new Font(Font.HELVETICA, 8, Font.BOLD)));
        k.setBackgroundColor(new Color(245, 247, 250));
        k.setPadding(4f);
        t.addCell(k);
        PdfPCell v = new PdfPCell(new Phrase(val, new Font(Font.HELVETICA, 8)));
        v.setPadding(4f);
        t.addCell(v);
    }

    private void addHeaderSpan(PdfPTable table, String txt, int colspan) {
        PdfPCell cell = new PdfPCell(new Phrase(txt, new Font(Font.HELVETICA, 9, Font.BOLD)));
        cell.setColspan(colspan);
        cell.setHorizontalAlignment(Element.ALIGN_LEFT);
        cell.setBackgroundColor(new Color(235, 240, 245));
        table.addCell(cell);
    }

    private void addHeader(PdfPTable table, String txt) {
        PdfPCell cell = new PdfPCell(new Phrase(txt, new Font(Font.HELVETICA, 8, Font.BOLD)));
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setBackgroundColor(new Color(245, 247, 250));
        table.addCell(cell);
    }

    private void addBody(PdfPTable table, String txt, int align, Color bg) {
        PdfPCell cell = new PdfPCell(new Phrase(txt, new Font(Font.HELVETICA, 8)));
        cell.setHorizontalAlignment(align);
        cell.setBackgroundColor(bg);
        table.addCell(cell);
    }

    private String fmtDouble(Double v) {
        if (v == null) return "-";
        return String.format(Locale.US, "%.2f", v);
    }

    private static class BucketAccum {
        final int sensorId; final long bucketStartMs;
        double flowSum = 0; int flowN = 0; Double flowMin = null; Double flowMax = null;
        double phSum = 0; int phN = 0; Double phMin = null; Double phMax = null;
        double turbSum = 0; int turbN = 0; Double turbMin = null; Double turbMax = null;
        double condSum = 0; int condN = 0; Double condMin = null; Double condMax = null;
        BucketAccum(int sid, long ms) { this.sensorId = sid; this.bucketStartMs = ms; }
        void accept(SensorRecordDTO r) {
            if (r.flowRate() != null) { double v = r.flowRate(); flowSum += v; flowN++; flowMin = flowMin==null? v : Math.min(flowMin, v); flowMax = flowMax==null? v : Math.max(flowMax, v);}
            if (r.ph() != null) { double v = r.ph(); phSum += v; phN++; phMin = phMin==null? v : Math.min(phMin, v); phMax = phMax==null? v : Math.max(phMax, v);}
            if (r.turbidity() != null) { double v = r.turbidity(); turbSum += v; turbN++; turbMin = turbMin==null? v : Math.min(turbMin, v); turbMax = turbMax==null? v : Math.max(turbMax, v);}
            if (r.conductivity() != null) { double v = r.conductivity(); condSum += v; condN++; condMin = condMin==null? v : Math.min(condMin, v); condMax = condMax==null? v : Math.max(condMax, v);}
        }
        BucketStat toStat() {
            BucketStat s = new BucketStat();
            s.sensorId = sensorId;
            s.bucketStart = Instant.ofEpochMilli(bucketStartMs);
            s.avgFlow = flowN>0? flowSum/flowN : null; s.minFlow = flowMin; s.maxFlow = flowMax;
            s.avgPh = phN>0? phSum/phN : null; s.minPh = phMin; s.maxPh = phMax;
            s.avgTurb = turbN>0? turbSum/turbN : null; s.minTurb = turbMin; s.maxTurb = turbMax;
            s.avgCond = condN>0? condSum/condN : null; s.minCond = condMin; s.maxCond = condMax;
            return s;
        }
    }
    private static class BucketStat {
        int sensorId; Instant bucketStart;
        Double avgFlow, minFlow, maxFlow;
        Double avgPh, minPh, maxPh;
        Double avgTurb, minTurb, maxTurb;
        Double avgCond, minCond, maxCond;
    }
}
