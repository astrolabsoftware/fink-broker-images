# Docker Images for Fink

This repository contains the unified Docker build system for Fink. It centralizes all image builds for both local development and Kubernetes deployment.

## Important Note

**This project only builds images with dependencies.** The fink-broker source code is embedded inside the images in the [fink-broker/](https://github.com/astrolabsoftware/fink-broker) repository and CI. The build procedure for Kubernetes (k8s) and sentinel images are now mutualized in this repository.

## Prerequisites

To build images, you need:

- **Go 1.23+**: Required for ciux installation
- **ciux v0.0.7+**: Container image build utility

### Installing ciux

1. Install Go 1.23+ and ensure it's in your PATH:
   ```bash
   export PATH=$(go env GOPATH)/bin:$PATH
   ```

2. Install ciux v0.0.7+:
   ```bash
   go install github.com/k8s-school/ciux@v0.0.7-rc1
   ```

For detailed installation instructions, see: https://github.com/k8s-school/ciux/blob/main/README.md#installation

### Image Types and Sizes

The dependency images are built for different purposes with varying sizes:

- **noscience (k8s)**: ~2.7-2.9GB - Kubernetes images with base dependencies and test packages only
- **science (k8s)**: ~6.6GB - Kubernetes images with additional science packages (astronomy libraries, dustmaps for ZTF)
- **sentinel**: ~6.8-8.2GB - Standalone monitoring images with full Kafka, HBase, Spark stack and service management

Use `docker images` to see locally available images and their sizes.

## Architecture

This repository provides a unified build system with the following structure:

### Core Build Files
- **Dockerfile.k8s**: Multi-stage Kubernetes images (noscience/science variants)
- **Dockerfile.sentinel**: Standalone monitoring images with full service stack
- **build-images.sh**: Unified build script for all image types
- **run_sentinel.sh**: Convenience script for running sentinel containers

### Container Filesystem (`containerfs/`)
- **install_miniconda.sh**: Python environment installation
- **install_python_deps.sh**: Unified Python dependency installer
- **k8s/jars-urls.${input_survey}.txt**: Spark JAR dependencies for Kubernetes images (per survey)
- **sentinel/**: Service installation scripts (Kafka, HBase, Spark) and startup scripts
- **rubin/deps/**: Rubin survey-specific Python requirements
- **ztf/deps/**: ZTF survey-specific Python requirements

## Workflow

We mainly use these in the Continuous Integration of various repositories. The image is built at each release of this repository:

```
# push modifications
git tag <number>
git push origin --tags

# then publish release on GH
```

The code is currently checked on `Almalinux:9`.

| | Latest |
|-|-----|
| OS | AlmaLinux 9 |
| Spark | 3.4.1 |
| Hadoop | 3.2 |
| Java |11 |
| HBase | 2.4.10 |
| Kafka | 2.8.1 |

The production environment is currently in use at VirtualData, Université Paris-Saclay, to process the ZTF alert stream. For development purposes, one can build locally images using the unified build script:

```bash
./build-images.sh -h
Usage: build-images.sh [options]

  Available options:
    -h                  this message
    -t TARGET           target to build: k8s, sentinel
    --noscience         build noscience image (k8s only, default: science)
    -i SURVEY           survey: ztf, rubin (default: ztf)
    --verbose           verbose build output

Build Fink Docker images:
  - k8s: Build Kubernetes image using Dockerfile.k8s
  - sentinel: Build sentinel development image (specify survey with -i)

Examples:
  build-images.sh -t k8s --noscience -i ztf        # K8s noscience image for ZTF
  build-images.sh -t k8s -i rubin                  # K8s science image for Rubin
  build-images.sh -t sentinel -i rubin             # Sentinel Rubin image
  build-images.sh -t sentinel -i ztf               # Sentinel ZTF image
```

This unified script replaces the previous separate build processes and supports both local development images (called Sentinel) and Kubernetes deployment images for both survey 'rubin' and 'ztf'.

### Building an image

Use the `build-images.sh` script for building images. This unified build script handles all build scenarios with proper argument validation:

```bash
# Build local development image for ZTF survey
./build-images.sh -t sentinel -i ztf

# Build local development image for Rubin survey
./build-images.sh -t sentinel -i rubin

# Build Kubernetes science image for ZTF
./build-images.sh -t k8s -i ztf

# Build Kubernetes noscience image for Rubin
./build-images.sh -t k8s --noscience -i rubin
```

### Start a container

```bash
# Build a sentinel image for ZTF survey
./build-images.sh -t sentinel -i ztf

# Or use the run_sentinel.sh script to run pre-built images
./run_sentinel.sh -t ztf

# Run an existing image manually
docker run -it --rm <image_tag> bash
```

Note that when starting a container, a script is launched to automatically start Apache HBase and Apache Kafka. Several environment variables are already defined inside the container (see each Dockerfile specifically).

### Deploy images

See https://docs.docker.com/docker-hub/repos/#pushing-a-docker-container-image-to-docker-hub.

Example:

```bash
$ docker images
REPOSITORY                TAG       IMAGE ID       CREATED          SIZE
julienpeloton/fink-ci     dev       d5ee1c3b1299   20 minutes ago   3.15GB

$ docker push julienpeloton/fink-ci:dev
The push refers to repository [docker.io/julienpeloton/fink-ci]
d3eeb8e94cd6: Pushed
970209ec3e0c: Pushed
529806cc03af: Pushed
174f56854903: Mounted from library/centos
```

### Create your own image

To create your own image with specific versions, you can:

1. **For K8s images**: Modify `Dockerfile.k8s` and the dependencies in `containerfs/k8s/jars-urls.${input_survey}.txt` or survey-specific dependencies in `containerfs/<survey>/deps/`

2. **For sentinel images**: Modify `Dockerfile.sentinel` and the service installation scripts in `containerfs/sentinel/`

3. **For new surveys**: Create a new survey folder in `containerfs/` with:
   - `deps/` directory containing Python requirements files
   - `python_version.sh` specifying the Python version
   - Update the build scripts to support the new survey

The unified `build-images.sh` script handles all build scenarios with proper argument validation.

## Image availability

Dependencies images are built by the CI and their names are displayed below each CI job summary. See the [GitHub Actions page](https://github.com/astrolabsoftware/fink-broker-images/actions) for the latest built images.

Image names follow this format: `gitlab-registry.in2p3.fr/astrolabsoftware/fink/fink-deps-<suffix>-<survey>:<version>`

Example: `gitlab-registry.in2p3.fr/astrolabsoftware/fink/fink-deps-noscience-ztf:v2.52.0-83-g8db26f3`

All images are publicly available in the GitLab registry at `gitlab-registry.in2p3.fr/astrolabsoftware/fink`.

## Running Sentinel Containers

Use `run_sentinel.sh` to quickly run pre-built sentinel containers from the GitLab registry:

```bash
# Run ZTF sentinel with latest tag
./run_sentinel.sh -t ztf

# Run Rubin sentinel with specific version
./run_sentinel.sh -t rubin --tag v2.52.0-83-g8db26f3

# Run with custom command
./run_sentinel.sh -t ztf --cmd "python --version"

# Mount local directory and expose port
./run_sentinel.sh -t ztf --mount ./workspace --port 8080:8080
```

The script automatically pulls the appropriate sentinel image from `gitlab-registry.in2p3.fr/astrolabsoftware/fink/fink-deps-sentinel-<survey>:<tag>`.
