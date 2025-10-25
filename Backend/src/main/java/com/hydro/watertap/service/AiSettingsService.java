package com.hydro.watertap.service;

import com.hydro.watertap.model.entity.AiSettingsEntity;
import com.hydro.watertap.repository.AiSettingsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
public class AiSettingsService {

    private final AiSettingsRepository repository;

    public AiSettingsService(AiSettingsRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public AiSettingsEntity getOrCreate() {
        List<AiSettingsEntity> all = repository.findAll();
        if (all.isEmpty()) {
            AiSettingsEntity def = AiSettingsEntity.builder()
                    .aiEnabled(true)
                    .workStart(LocalTime.of(8, 0))
                    .workEnd(LocalTime.of(18, 0))
                    .monday(true).tuesday(true).wednesday(true).thursday(true).friday(true)
                    .saturday(false).sunday(false)
                    .build();
            return repository.save(def);
        }
        return all.get(0);
    }

    @Transactional
    public AiSettingsEntity save(AiSettingsEntity settings) { return repository.save(settings); }

    public boolean isAiEnabled() { return getOrCreate().isAiEnabled(); }

    @Transactional
    public void setAiEnabled(boolean enabled) {
        AiSettingsEntity s = getOrCreate();
        s.setAiEnabled(enabled);
        repository.save(s);
    }

    public boolean isWorkTime(LocalDateTime now) {
        AiSettingsEntity s = getOrCreate();
        DayOfWeek dow = now.getDayOfWeek();
        boolean dayAllowed = switch (dow) {
            case MONDAY -> s.isMonday();
            case TUESDAY -> s.isTuesday();
            case WEDNESDAY -> s.isWednesday();
            case THURSDAY -> s.isThursday();
            case FRIDAY -> s.isFriday();
            case SATURDAY -> s.isSaturday();
            case SUNDAY -> s.isSunday();
        };
        if (!dayAllowed) return false;
        LocalTime start = s.getWorkStart();
        LocalTime end = s.getWorkEnd();
        if (start == null || end == null) return true; // si no hay horario configurado, considerar como hay gente
        LocalTime t = now.toLocalTime();
        if (end.isAfter(start)) {
            return !t.isBefore(start) && !t.isAfter(end);
        } else { // horario nocturno cruzando medianoche
            return !t.isBefore(start) || !t.isAfter(end);
        }
    }
}
