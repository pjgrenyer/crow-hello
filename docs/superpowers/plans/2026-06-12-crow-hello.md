# Crow Hello-World Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal C++ HTTP server using Crow that returns "Hello, World!" on `GET /`, runnable in a multi-stage Docker container.

**Architecture:** Single `main.cpp` containing a `crow::SimpleApp` with one route, built with CMake (using `FetchContent` to pull Crow), packaged via a two-stage Dockerfile (Debian-based builder + slim runtime).

**Tech Stack:** C++17, Crow (header-only), CMake 3.16+, Asio, Debian bookworm-slim, Docker.

---

## File Structure

```
crow-hello/
├── CMakeLists.txt        # FetchContent for Crow, single executable target
├── Dockerfile            # Two-stage: builder + runtime
├── .dockerignore         # Exclude build/, .git, IDE files
├── README.md             # Build & run instructions
└── src/
    └── main.cpp          # Crow app with one route
```

Each file has a single, clear responsibility. The whole project is small enough to hold in context at once.

---

## Task 1: Create the C++ source

**Files:**
- Create: `src/main.cpp`

- [ ] **Step 1: Write `src/main.cpp`**

```cpp
#include <crow.h>

int main() {
    crow::SimpleApp app;

    CROW_ROUTE(app, "/")([]{
        return "Hello, World!";
    });

    app.port(8080).multithreaded().run();
    return 0;
}
```

- [ ] **Step 2: Commit**

```bash
git add src/main.cpp
git commit -m "feat: add Crow hello-world source"
```

---

## Task 2: Create the CMake build configuration

**Files:**
- Create: `CMakeLists.txt`

- [ ] **Step 1: Write `CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.16)
project(crow-hello CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)
FetchContent_Declare(
    Crow
    GIT_REPOSITORY https://github.com/CrowCpp/Crow.git
    GIT_TAG        v1.2.0
)
set(CROW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(CROW_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(Crow)

add_executable(crow-hello src/main.cpp)
target_link_libraries(crow-hello PRIVATE Crow::Crow)
```

Notes for the implementer:
- Crow v1.2.0 is the latest stable tag at time of writing.
- `Crow::Crow` is the imported target Crow exposes; it transitively brings in Asio and threads.
- We disable Crow's own examples and tests to keep the configure step quick.

- [ ] **Step 2: Commit**

```bash
git add CMakeLists.txt
git commit -m "build: add CMake config with FetchContent for Crow"
```

---

## Task 3: Verify the build works locally (sanity check)

This task is optional — skip if the implementer doesn't have a local C++ toolchain. The Docker build in Task 5 will validate the build regardless.

**Files:** none (no edits)

- [ ] **Step 1: Configure**

Run: `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
Expected: configures successfully, fetches Crow into `build/_deps/crow-src/`.

- [ ] **Step 2: Build**

Run: `cmake --build build -j`
Expected: produces `build/crow-hello` executable. No errors.

- [ ] **Step 3: Quick smoke test (optional)**

Run: `./build/crow-hello &` then `curl -s http://localhost:8080`
Expected output: `Hello, World!`
Then: `kill %1` to stop it.

- [ ] **Step 4: No commit needed** (build artefacts are not committed; they'll be excluded by `.dockerignore` and `.gitignore` in Task 6).

---

## Task 4: Create the .dockerignore

**Files:**
- Create: `.dockerignore`

- [ ] **Step 1: Write `.dockerignore`**

```
build/
.git
.gitignore
.vscode/
.idea/
.DS_Store
*.swp
docs/
README.md
```

Notes:
- `docs/` and `README.md` are excluded because they aren't needed inside the image and only inflate the build context.

- [ ] **Step 2: Commit**

```bash
git add .dockerignore
git commit -m "build: add .dockerignore"
```

---

## Task 5: Create the multi-stage Dockerfile

**Files:**
- Create: `Dockerfile`

- [ ] **Step 1: Write `Dockerfile`**

```dockerfile
# ---- Stage 1: builder ----
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        ca-certificates \
        libasio-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY CMakeLists.txt ./
COPY src/ ./src/

RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j

# ---- Stage 2: runtime ----
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/build/crow-hello /usr/local/bin/crow-hello

EXPOSE 8080
CMD ["crow-hello"]
```

Notes for the implementer:
- `ca-certificates` in the builder is needed for `git` to clone Crow over HTTPS.
- `ca-certificates` in the runtime is harmless and useful if the server later makes outbound HTTPS calls; you can remove it if you want a still-smaller image.
- `git` is required because `FetchContent` clones Crow.
- `libasio-dev` provides Asio headers; Crow's CMake will use the system Asio.

- [ ] **Step 2: Build the image**

Run: `docker build -t crow-hello .`
Expected: build succeeds, final image is produced. The build will take a couple of minutes the first time as Crow is cloned and compiled.

- [ ] **Step 3: Run the container and verify**

Run (in one terminal): `docker run --rm -p 8080:8080 --name crow-hello-test crow-hello`
Expected: log line indicating Crow is listening on port 8080.

Run (in another terminal): `curl -s http://localhost:8080`
Expected output: `Hello, World!`

Then stop the container: `docker stop crow-hello-test` (or Ctrl-C in the run terminal).

- [ ] **Step 4: Commit**

```bash
git add Dockerfile
git commit -m "build: add multi-stage Dockerfile"
```

---

## Task 6: Add a .gitignore

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Write `.gitignore`**

```
build/
.DS_Store
.vscode/
.idea/
*.swp
```

- [ ] **Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: add .gitignore"
```

---

## Task 7: Add the README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write `README.md`**

````markdown
# crow-hello

A minimal C++ "Hello, World!" HTTP server using [Crow](https://github.com/CrowCpp/Crow), built and run in Docker.

## Build & run

```
docker build -t crow-hello .
docker run --rm -p 8080:8080 crow-hello
```

In another terminal:

```
curl http://localhost:8080
# => Hello, World!
```

## Project layout

- `src/main.cpp` — Crow app with a single `GET /` route.
- `CMakeLists.txt` — uses CMake `FetchContent` to pull Crow at configure time.
- `Dockerfile` — two stages: a Debian builder with the toolchain, and a slim runtime stage that contains only the compiled binary.
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with build & run instructions"
```

---

## Final verification

- [ ] **Step 1: Clean build from scratch**

Run: `docker build --no-cache -t crow-hello .`
Expected: succeeds end-to-end with no warnings about missing files.

- [ ] **Step 2: Run and curl**

Run: `docker run --rm -p 8080:8080 crow-hello` (in one terminal)
Run: `curl -s http://localhost:8080` (in another)
Expected output: `Hello, World!`

- [ ] **Step 3: Confirm working tree is clean**

Run: `git status`
Expected: `nothing to commit, working tree clean`.
