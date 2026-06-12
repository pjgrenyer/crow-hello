# crow-hello

A minimal C++ "Hello, World!" HTTP server using [Crow](https://github.com/CrowCpp/Crow).

## Build & run with Docker

```
docker build -t crow-hello .
docker run --rm -p 8080:8080 crow-hello
```

In another terminal:

```
curl http://localhost:8080
# => Hello, World!
```

## Build & run locally

Requires CMake ≥ 3.16 and standalone Asio headers. On Debian/Ubuntu, install the latest GCC (14) alongside the build tools:

```
sudo apt install cmake g++-14 libasio-dev
```

Configure and build, pointing CMake at `g++-14`:

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=g++-14
cmake --build build -j
./build/crow-hello
```

The first configure pulls Crow v1.2.0 via CMake `FetchContent`, so it needs network access; later builds reuse `build/_deps/`.

## Project layout

- `src/main.cpp` — Crow app with a single `GET /` route.
- `CMakeLists.txt` — uses CMake `FetchContent` to pull Crow at configure time.
- `Dockerfile` — two stages: a Debian builder with the toolchain, and a slim runtime stage that contains only the compiled binary.
