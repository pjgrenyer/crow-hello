# A C++ "Hello, World!" on the public internet

I have been reviewing Fran Buontempo's new C++ book, and somewhere between the chapters on modern idioms and the bits where she nudges you to actually *do* something with the language, I caught the itch. I have not written any C++ in more than twenty years — it is not what I do for a living — and the book reminded me how much the language has moved on without me. I wanted to host something small, written in modern C++, on a URL I could share. This project is the result.

The brief I gave myself was deliberately tiny. A single HTTP endpoint that returns `Hello, World!`, built in C++, deployed somewhere real, with the whole thing reproducible from a fresh checkout. The point was not to ship a product. It was to walk the full path — source to running container to public URL — without skipping the awkward middle bit where most side projects quietly die.

For the HTTP layer I picked [Crow](https://github.com/CrowCpp/Crow), a header-only framework with a Flask-shaped API. Header-only matters here because it keeps the build story honest: no system package to chase, no version mismatch between dev and CI. CMake's `FetchContent` pulls Crow v1.2.0 at configure time, and from then on the build is self-contained.

The whole server is twelve lines:

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

That is the entire C++ surface area of the project. A `SimpleApp`, one route, a lambda that returns a string, and `multithreaded().run()` to actually serve requests. Bear in mind that `CROW_ROUTE` is a macro doing real work — it registers the handler at compile time — but from the outside it reads almost exactly like the Python equivalent, which is the point.

The build sits in a two-stage Dockerfile. The first stage is a Debian image with `build-essential`, `cmake`, and `libasio-dev`, which compiles a release binary. The second stage is a slim Debian image that contains only the compiled binary and `ca-certificates`. 

For hosting Claude stubbonly insisted I go with AWS Lightsail's Container Service on the Nano tier — about seven dollars a month, with a built-in container registry so I do not need to wire up ECR or IAM roles for image pushes. Terraform provisions the service; a Makefile orchestrates the three steps of a deploy: `terraform apply` to ensure the service exists, `aws lightsail push-container-image` to upload a freshly built image, and a second `terraform apply` to roll out the new version. `make deploy` runs the lot.

Claude suggested that next, I should like to add a second route that does something genuinely C++-shaped — perhaps a small numerical endpoint, or something that exercises a library you would not casually reach for in Python. However, I've achived what I wanted.