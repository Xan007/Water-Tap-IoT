package com.hydro.watertap.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Getter
@Component
public class SupabaseProperties {
    @Value("${supabase.issuer}")
    private String issuer;

}
