package com.hydro.watertap.controller;

import com.hydro.watertap.service.PdfReportService;
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
@Tag(name = "Reports", description = "Generación de reportes PDF de sensores")
public class ReportController {

    private final PdfReportService reportService;

    public ReportController(PdfReportService reportService) {
        this.reportService = reportService;
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

