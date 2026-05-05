ARG CNPG_BASE_TAG=18.1-standard-bookworm
ARG PGVECTORSCALE_VERSION=0.9.0
ARG PG_TEXTSEARCH_VERSION=1.1.0

FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS extractor

ARG TARGETARCH
ARG PGVECTORSCALE_VERSION
ARG PG_TEXTSEARCH_VERSION

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl unzip ca-certificates dpkg \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
RUN set -eux; \
    curl -fsSL -o pgvectorscale.zip \
        "https://github.com/timescale/pgvectorscale/releases/download/${PGVECTORSCALE_VERSION}/pgvectorscale-${PGVECTORSCALE_VERSION}-pg18-${TARGETARCH}.zip"; \
    unzip -j pgvectorscale.zip "pgvectorscale-postgresql-18_*.deb" -d .; \
    dpkg-deb -x pgvectorscale-postgresql-18_*.deb /out; \
    \
    curl -fsSL -o pg-textsearch.zip \
        "https://github.com/timescale/pg_textsearch/releases/download/v${PG_TEXTSEARCH_VERSION}/pg-textsearch-v${PG_TEXTSEARCH_VERSION}-pg18-${TARGETARCH}.zip"; \
    unzip -j pg-textsearch.zip "pg-textsearch-postgresql-18_*.deb" -d .; \
    dpkg-deb -x pg-textsearch-postgresql-18_*.deb /out; \
    \
    rm -rf /out/usr/share/doc

FROM ghcr.io/cloudnative-pg/postgresql:${CNPG_BASE_TAG}

USER root
COPY --from=extractor /out/usr/lib/postgresql/18/lib/         /usr/lib/postgresql/18/lib/
COPY --from=extractor /out/usr/share/postgresql/18/extension/ /usr/share/postgresql/18/extension/
USER postgres
