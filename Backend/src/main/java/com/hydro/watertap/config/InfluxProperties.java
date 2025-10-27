package com.hydro.watertap.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class InfluxProperties {

    @Value("${influx.url}")
    private String url;

    @Value("${influx.database}")
    private String database;

    @Value("${influx.token}")
    private String token;

    @Value("${influx.org:}")
    private String org;

    public String getUrl() { return url; }
    public String getDatabase() { return database; }
    public String getToken() { return token; }
    public String getOrg() { return org; }
}
