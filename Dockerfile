FROM harbor.online.tkbbank.ru/custom-base-images/openjre-alpine-musl:21.0.8
RUN addgroup -S app && adduser -S -G app -h /app app
RUN apk add --no-cache curl
WORKDIR /app
COPY deploy/payconfig-server-*.jar /app/app.jar
RUN chown -R app:app /app
USER app
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -Duser.timezone=GMT+3 -jar /app/app.jar"]
