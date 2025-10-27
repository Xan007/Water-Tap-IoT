package com.hydro.watertap.controller;

import com.hydro.watertap.service.PdfReportService;
import com.hydro.watertap.service.CsvReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@RestController
@RequestMapping("/reports")
@Tag(name = "Reports", description = "Generación de reportes PDF y CSV de sensores")
public class ReportController {

    private final PdfReportService reportService;
    private final CsvReportService csvReportService;

    public ReportController(PdfReportService reportService, CsvReportService csvReportService) {
        this.reportService = reportService;
        this.csvReportService = csvReportService;
    }

    @GetMapping(produces = MediaType.APPLICATION_PDF_VALUE)
    @Operation(summary = "Genera un reporte PDF", description = "Parámetros: amount (int), unit (m|h|d), agg opcional (e.g., 1h, 1d)")
    public ResponseEntity<byte[]> generate(
            @RequestParam(name = "amount", defaultValue = "1") int amount,
            @RequestParam(name = "unit", defaultValue = "d") String unit,
            @RequestParam(name = "agg", required = false) String agg
    ) {
        if (amount <= 0) amount = 1;
        ChronoUnit chrono = parseUnit(unit);
        Instant to = Instant.now();
        Instant from = to.minus(amount, chrono);

        byte[] pdf = reportService.generateReport(from, to, agg);
        String filename = "reporte-" + unit + amount + ".pdf";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=" + filename)
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    @GetMapping(value = "/csv", produces = "text/csv")
    @Operation(summary = "Genera un reporte CSV", description = "CSV con datos crudos y estadísticas por buckets. Parámetros: amount (int), unit (m|h|d)")
    public ResponseEntity<byte[]> generateCsv(
            @RequestParam(name = "amount", defaultValue = "1") int amount,
            @RequestParam(name = "unit", defaultValue = "d") String unit
    ) {
        if (amount <= 0) amount = 1;
        ChronoUnit chrono = parseUnit(unit);
        Instant to = Instant.now();
        Instant from = to.minus(amount, chrono);

        byte[] csv = csvReportService.generateCsv(from, to);
        String filename = "reporte-" + unit + amount + ".csv";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + filename)
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(csv);
    }

    private ChronoUnit parseUnit(String unit) {
        if (unit == null) return ChronoUnit.DAYS;
        String u = unit.trim().toLowerCase();
        switch (u) {
            case "m": case "min": case "mins": case "minute": case "minutes": case "minuto": case "minutos":
                return ChronoUnit.MINUTES;
            case "h": case "hr": case "hour": case "hours": case "hora": case "horas":
                return ChronoUnit.HOURS;
            case "d": case "day": case "days": case "dia": case "dias":
            default:
                return ChronoUnit.DAYS;
        }
    }
}
