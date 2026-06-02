FROM harbor.online.tkbbank.ru/custom-base-images/openjre-alpine-musl:21.0.8
RUN addgroup -S app && adduser -S -G app -h /app app
RUN apk add --no-cache curl openssl

# Trust the corp git server's certificate chain so JGit can clone the config-repo over HTTPS
# with TLS verification ON (no skip-ssl-validation). The chain is fetched at build time from
# git.tkbbank.ru (the corp CI runner has network access to it) and imported into the JRE truststore.
RUN set -eux; \
    : "${JAVA_HOME:?JAVA_HOME must be set}"; \
    echo | openssl s_client -connect git.tkbbank.ru:443 -servername git.tkbbank.ru -showcerts 2>/dev/null > /tmp/raw.pem; \
    awk '/-----BEGIN CERTIFICATE-----/{n++; cap=1} cap{print > ("/tmp/cert-" n ".pem")} /-----END CERTIFICATE-----/{cap=0}' /tmp/raw.pem; \
    test -s /tmp/cert-1.pem || { echo "ERROR: no certificate fetched from git.tkbbank.ru:443"; exit 1; }; \
    for c in /tmp/cert-*.pem; do \
        keytool -importcert -trustcacerts -noprompt -alias "tkbbank-$(basename "$c" .pem)" \
            -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit -file "$c"; \
    done; \
    rm -f /tmp/raw.pem /tmp/cert-*.pem

WORKDIR /app
COPY deploy/payconfig-server-*.jar /app/app.jar
RUN chown -R app:app /app
USER app
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -Duser.timezone=GMT+3 -jar /app/app.jar"]
