FROM swift:5.6-focal as build

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY ./Package.* ./
RUN swift package resolve
COPY . .
RUN swift build -c release

WORKDIR /staging
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Run" ./ \
    && mv /build/Resources ./Resources && chmod -R a-w ./Resources

FROM swift:5.6-focal-slim

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io \
    && rm -r /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /staging /app

EXPOSE 8080

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
