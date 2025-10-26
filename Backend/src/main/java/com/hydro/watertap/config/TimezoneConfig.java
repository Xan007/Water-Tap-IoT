package com.hydro.watertap.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;

import java.time.ZoneId;
import java.util.TimeZone;

@Configuration
public class TimezoneConfig {
    private static final Logger log = LoggerFactory.getLogger(TimezoneConfig.class);

    @PostConstruct
    public void init() {
        String zone = "America/Bogota";
        TimeZone tz = TimeZone.getTimeZone(zone);
        TimeZone.setDefault(tz);
        System.setProperty("user.timezone", zone);
        log.info("Zona horaria por defecto establecida a {}", ZoneId.of(zone));
    }
}

