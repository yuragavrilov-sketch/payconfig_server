package ru.copperside.configserver;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowableOfType;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "spring.profiles.active=native",
                "spring.cloud.config.server.native.search-locations=classpath:/config-repo-test",
                "config-server.security.basic-auth-enabled=true",
                "spring.security.user.name=tester",
                "spring.security.user.password=secret"
        }
)
class ConfigServerSecurityTests {

    @LocalServerPort
    int port;

    RestClient anonymous;
    RestClient authenticated;

    @BeforeEach
    void setUp() {
        String base = "http://localhost:" + port;
        anonymous = RestClient.builder().baseUrl(base).build();
        authenticated = RestClient.builder()
                .baseUrl(base)
                .defaultHeaders(h -> {
                    String encoded = java.util.Base64.getEncoder()
                            .encodeToString("tester:secret".getBytes());
                    h.set("Authorization", "Basic " + encoded);
                })
                .build();
    }

    @Test
    void healthIsOpenWithoutCredentials() {
        ResponseEntity<String> response = anonymous.get()
                .uri("/actuator/health")
                .retrieve()
                .toEntity(String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void configEndpointRequiresCredentials() {
        RestClientResponseException ex = catchThrowableOfType(
                RestClientResponseException.class,
                () -> anonymous.get()
                        .uri("/application/default")
                        .retrieve()
                        .toEntity(String.class)
        );
        assertThat(ex).isNotNull();
        assertThat(ex.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void configEndpointReachableWithCredentials() {
        ResponseEntity<String> response = authenticated.get()
                .uri("/application/default")
                .retrieve()
                .toEntity(String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
