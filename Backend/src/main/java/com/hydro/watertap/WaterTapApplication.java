package com.hydro.watertap;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class WaterTapApplication {
    public static void main(String[] args) {
        SpringApplication.run(WaterTapApplication.class, args);
    }
}
