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

## Deploy to AWS Lightsail

Hosted on a Lightsail Container Service (Nano tier, ~$7/mo). The image is pushed to Lightsail's built-in container registry — no ECR needed.

Prerequisites:

- `terraform`, `docker`, the `aws` CLI, and the [`lightsailctl`](https://lightsail.aws.amazon.com/ls/docs/en_us/articles/amazon-lightsail-install-software) plugin on `PATH`.
- `terraform/secrets.tfvars` (gitignored) containing:

  ```
  aws_access_key = "AKIA..."
  aws_secret_key = "..."
  ```

  See `terraform/secrets.tfvars.example`.
- If your shell has `AWS_PROFILE` / `AWS_SESSION_TOKEN` set for a different account, `unset` them first — env vars override the static keys in `secrets.tfvars`.

First time:

```
cd terraform && terraform init && cd ..
make deploy
```

Subsequent deploys (rebuild, push, redeploy):

```
make deploy
```

`make deploy` runs three steps:

1. `terraform apply` — ensures the container service exists.
2. `aws lightsail push-container-image` — builds the image and uploads it; Lightsail assigns a version like `:crow-hello.crow-hello.3`, captured in `.last-image`.
3. `terraform apply -var image=…` — rolls out that version.

Get the public URL:

```
make url
```

Override defaults via env vars, e.g. `REGION=us-east-1 SERVICE_NAME=foo make deploy`.

### Tear down

The container service bills monthly until destroyed. To remove everything:

```
cd terraform
terraform destroy -var-file=secrets.tfvars
```

## Project layout

- `src/main.cpp` — Crow app with a single `GET /` route.
- `CMakeLists.txt` — uses CMake `FetchContent` to pull Crow at configure time.
- `Dockerfile` — two stages: a Debian builder with the toolchain, and a slim runtime stage that contains only the compiled binary.
- `terraform/` — Lightsail container service + deployment.
- `Makefile` — `make deploy` builds, pushes, and rolls out a new version.
