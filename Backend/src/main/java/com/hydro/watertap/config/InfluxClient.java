package com.hydro.watertap.config;

import com.hydro.watertap.config.InfluxProperties;
import com.influxdb.v3.client.InfluxDBClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class InfluxClient {

    private final InfluxProperties influxProperties;

    public InfluxClient(InfluxProperties influxProperties) {
        this.influxProperties = influxProperties;
    }

    @Bean
    public InfluxDBClient influxDBClient() {
        return InfluxDBClient.getInstance(
                influxProperties.getUrl(),
                influxProperties.getToken().toCharArray(),
                null
        );
    }
}
