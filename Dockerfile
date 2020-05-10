FROM oracle/graalvm-ce:20.0.0-java11 as builder
RUN gu install native-image
RUN curl https://bintray.com/sbt/rpm/rpm | tee /etc/yum.repos.d/bintray-sbt-rpm.repo && \
    yum install -y sbt
COPY . /build
WORKDIR /build
RUN curl -L -o musl.tar.gz \
    https://github.com/gradinac/musl-bundle-example/releases/download/v1.0/musl.tar.gz && \
    tar -xvzf musl.tar.gz
RUN sbt clean compile fullOptJS
RUN sbt server/graalvm-native-image:packageBin

FROM alpine
RUN apk add --no-cache wget
RUN wget http://get.docker.com/builds/Linux/x86_64/docker-latest.tgz
RUN apk del wget
RUN tar -xvzf docker-latest.tgz
RUN mv docker/docker /usr/bin
RUN rm -rf docker docker-latest.tgz
COPY --from=builder /build/server/target/graalvm-native-image/server /docker-stats-monitor/server
COPY --from=builder /build/static /docker-stats-monitor/static
RUN rm /docker-stats-monitor/static/js/client.js.map
WORKDIR /docker-stats-monitor
EXPOSE 8080
ENTRYPOINT [ "./server" ]
