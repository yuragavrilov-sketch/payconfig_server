package ru.copperside.configserver;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    /**
     * Production chain: health probes stay open for Kubernetes; every other
     * endpoint (the Config Server API) requires HTTP Basic authentication.
     */
    @Bean
    @ConditionalOnProperty(name = "payconfig-server.security.basic-auth-enabled", havingValue = "true")
    SecurityFilterChain securedFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/actuator/health", "/actuator/health/**").permitAll()
                        .anyRequest().authenticated())
                .httpBasic(Customizer.withDefaults())
                .csrf(csrf -> csrf.disable());
        return http.build();
    }

    /**
     * Default/local chain: everything open, so the local contour and clients
     * that send no credentials keep working unchanged.
     */
    @Bean
    @ConditionalOnProperty(name = "payconfig-server.security.basic-auth-enabled", havingValue = "false", matchIfMissing = true)
    SecurityFilterChain openFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                .csrf(csrf -> csrf.disable());
        return http.build();
    }
}
