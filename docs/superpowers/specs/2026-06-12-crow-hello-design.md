# Crow Hello-World Server — Design

**Date:** 2026-06-12
**Status:** Approved

## Goal

A minimal C++ HTTP server using the [Crow](https://github.com/CrowCpp/Crow) framework, built and run inside a Docker container. The purpose is to see Crow working end-to-end in a container — a clean skeleton, not a production service.

Success criteria: `docker build` produces an image; `docker run -p 8080:8080 crow-hello` starts the server; `curl http://localhost:8080` returns `Hello, World!`.

## Project layout

```
crow-hello/
├── CMakeLists.txt
├── Dockerfile
├── .dockerignore
├── README.md
└── src/
    └── main.cpp
```

## Components

### `src/main.cpp`

A ~10-line Crow app:

- Include `<crow.h>`
- Define `crow::SimpleApp app`
- One route: `CROW_ROUTE(app, "/")([]{ return "Hello, World!"; });`
- `app.port(8080).multithreaded().run();`

The server binds to `0.0.0.0:8080` (Crow's default when running multithreaded in a container).

### `CMakeLists.txt`

- `cmake_minimum_required(VERSION 3.16)`
- C++17 standard
- Uses `FetchContent` to pull Crow from its GitHub release tag. Crow is header-only, so no separate install step is needed.
- Links against system Asio (installed via `libasio-dev` in the builder image) and `pthread`.
- Produces a single executable target `crow-hello` from `src/main.cpp`.

### `Dockerfile`

Two stages:

**Stage 1 — `builder`** (based on `debian:bookworm-slim`):
- `apt-get install` `build-essential`, `cmake`, `git`, `libasio-dev`
- Copy `CMakeLists.txt` and `src/`
- Run `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j`

**Stage 2 — `runtime`** (based on `debian:bookworm-slim`):
- Copy `/build/crow-hello` from the builder stage to `/usr/local/bin/`
- `EXPOSE 8080`
- `CMD ["crow-hello"]`

The runtime stage installs no build tools, keeping the final image small.

### `.dockerignore`

Excludes `build/`, `.git`, `.vscode/`, `.idea/`, and any local CMake artefacts so the build context stays small.

### `README.md`

Brief instructions:

```
docker build -t crow-hello .
docker run --rm -p 8080:8080 crow-hello
curl http://localhost:8080
```

## Out of scope (deliberate YAGNI)

- No tests
- No CI config
- No logging, config files, or environment variables
- No graceful shutdown handling
- No health endpoint
- No additional routes
- No HTTPS / reverse proxy

These can be added later if the skeleton grows into a real project.
