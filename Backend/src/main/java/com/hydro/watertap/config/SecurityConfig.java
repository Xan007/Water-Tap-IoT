package com.hydro.watertap.config;

import com.hydro.watertap.config.SupabaseProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@Configuration
public class SecurityConfig {

    private final SupabaseProperties supabaseProperties;

    public SecurityConfig(SupabaseProperties supabaseProperties) {
        this.supabaseProperties = supabaseProperties;
    }

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        http
                .authorizeExchange(exchanges -> exchanges
                        .anyExchange().permitAll()
                )
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .jwkSetUri(supabaseProperties.getIssuer() + "/auth/v1/.well-known/jwks.json")
                        )
                )
                .cors(cors -> {})
                .csrf(ServerHttpSecurity.CsrfSpec::disable);

        return http.build();
    }
}
