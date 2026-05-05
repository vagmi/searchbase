# searchbase

CloudNativePG-compatible PostgreSQL 18 image bundling three search/vector extensions:

| Extension       | Version | Source                                       |
| --------------- | ------- | -------------------------------------------- |
| pgvector        | 0.8.1   | preinstalled in the CNPG base image          |
| pgvectorscale   | 0.9.0   | https://github.com/timescale/pgvectorscale   |
| pg_textsearch   | 1.1.0   | https://github.com/timescale/pg_textsearch   |

Base image: `ghcr.io/cloudnative-pg/postgresql:18.1-standard-bookworm` (Debian 12, glibc 2.36).

Built for `linux/amd64` and `linux/arm64`. Published as `ghcr.io/vagmi/searchbase`.

## Pulling

```sh
docker pull ghcr.io/vagmi/searchbase:latest
```

Tags follow `docker/metadata-action` defaults: branch, semver (`v1.2.3` → `1.2.3`, `1.2`), short SHA, and `latest` on the default branch.

## Using with CloudNativePG

`pg_textsearch` requires its library to be loaded at server start, so it has to go in `shared_preload_libraries`. In a `Cluster` spec:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: example
spec:
  imageName: ghcr.io/vagmi/searchbase:latest
  postgresql:
    shared_preload_libraries:
      - pg_textsearch
```

Then in your database:

```sql
CREATE EXTENSION vector;
CREATE EXTENSION vectorscale CASCADE;  -- pulls in vector if not present
CREATE EXTENSION pg_textsearch;
```

`pgvectorscale` does **not** need to be in `shared_preload_libraries`.

## Local development

A `docker-compose.yaml` is provided that mirrors the CNPG runtime layout: a privileged init container chowns the data volume and runs `initdb`, then the main container starts `postgres` with `pg_textsearch` preloaded.

```sh
docker-compose up -d
PGPASSWORD=postgres psql -h localhost -U postgres
```

The default password (`postgres`) is set in the compose file — change it before sharing.

Tear down with `docker-compose down -v` (the `-v` drops the data volume).

## Building the image yourself

```sh
docker buildx build --platform linux/amd64 --load -t searchbase:dev .
```

For multi-arch:

```sh
docker buildx build --platform linux/amd64,linux/arm64 -t searchbase:dev .
```

Bumping extension versions: edit the `ARG PGVECTORSCALE_VERSION` and `ARG PG_TEXTSEARCH_VERSION` defaults in the `Dockerfile`, or pass `--build-arg` on the CLI.

## CI

`.github/workflows/build-push.yaml` builds each architecture on its native GitHub runner (`ubuntu-latest` for amd64, `ubuntu-24.04-arm` for arm64) in parallel, pushes by digest, and a final job merges the digests into one multi-arch manifest. No qemu emulation is involved.
