# payconfig-server

Spring Cloud Config Server for PAY_ALL. Serves non-secret configuration to the Spring
services. Secrets stay in Vault. This service is the documented exception to the
`spring.config.import` rule (it is the configuration source).

> Own Git repository (`github.com/yuragavrilov-sketch/payconfig_server`, branch `main`).
> `infra/docker-compose.yaml` builds the `payconfig-server` image from the local working copy,
> and `infra/k8s/payconfig-server/` holds the production manifests.

## Profiles

| Profile | Backend | Auth | Use |
|---------|---------|------|-----|
| `local` (default) | file `file:///config-repo` | open | local / compose contour |
| `prod` | GitLab git remote | HTTP Basic | Kubernetes |

## Environment variables (prod)

| Variable | Meaning |
|----------|---------|
| `CONFIG_GIT_URI` | GitLab config-repo URL |
| `CONFIG_GIT_USERNAME` / `CONFIG_GIT_PASSWORD` | GitLab credentials (PAT / deploy token) |
| `CONFIG_GIT_LABEL` | environment branch (default `prod`) |
| `CONFIG_SERVER_USER` / `CONFIG_SERVER_PASSWORD` | Basic-auth credentials clients must send |
| `SERVER_PORT` | listen port (default `8080`) |

`payconfig-server.security.basic-auth-enabled` toggles Basic auth (off by default, on in `prod`).
Health probes (`/actuator/health/**`) stay open regardless.

## Build and run

```bash
mvn -q -B test            # unit + security tests
mvn -q -B package         # produces target/app.jar
docker build -t payconfig-server:1.0.0 .
```

Local run (file backend, open): start via `infra/docker-compose.yaml` (`payconfig-server` service,
host port 8888).

Production run: see `infra/k8s/payconfig-server/README.md`.

## Client dependency

Enabling Basic auth requires every client to send `spring.cloud.config.username/password`.
This wiring is tracked as a separate task. See ADR-0008.
