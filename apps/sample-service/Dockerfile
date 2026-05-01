# syntax=docker/dockerfile:1.7

# --- build -------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS build

ARG TARGETARCH
ARG TARGETOS
ARG VERSION=dev

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" \
    -o /out/sample-service ./

# --- runtime -----------------------------------------------------------------
FROM gcr.io/distroless/static-debian12:nonroot

ARG VERSION=dev
ARG SOURCE_COMMIT=unknown

LABEL org.opencontainers.image.title="sample-service" \
      org.opencontainers.image.description="Canary workload for terrascale-platform" \
      org.opencontainers.image.source="https://github.com/yurykuvaev/terrascale-platform" \
      org.opencontainers.image.vendor="Yury Kuvaev" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${SOURCE_COMMIT}"

USER nonroot:nonroot
WORKDIR /app

COPY --from=build /out/sample-service /app/sample-service

EXPOSE 8080
ENV ADDR=":8080"

ENTRYPOINT ["/app/sample-service"]
