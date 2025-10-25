package com.hydro.watertap.controller;

import com.hydro.watertap.model.entity.AiSettingsEntity;
import com.hydro.watertap.service.AiSettingsService;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/ai")
@Tag(name = "AI Settings", description = "Configurar IA y horarios")
public class AiSettingsController {

    private final AiSettingsService service;

    public AiSettingsController(AiSettingsService service) { this.service = service; }

    @GetMapping("/settings")
    public AiSettingsEntity get() { return service.getOrCreate(); }

    @PostMapping("/settings")
    public AiSettingsEntity save(@RequestBody AiSettingsEntity settings) {
        if (settings.getId() == null) {
            // merge sobre existente para evitar múltiples filas
            AiSettingsEntity existing = service.getOrCreate();
            settings.setId(existing.getId());
        }
        return service.save(settings);
    }

    @PostMapping("/enable")
    public void enable() { service.setAiEnabled(true); }

    @PostMapping("/disable")
    public void disable() { service.setAiEnabled(false); }
}

