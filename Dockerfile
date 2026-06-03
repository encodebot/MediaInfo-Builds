FROM ubuntu:26.04 AS builder

# Enforce strict error handling. Instantly aborts on any hidden failure.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend for apt to prevent hanging prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites required for MediaInfo compilation
# We intentionally omit extra libraries to ensure the binary remains highly portable.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    xz-utils \
    ca-certificates \
    automake \
    autoconf \
    libtool \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Accept MediaInfo version as a dynamic build argument
ARG MI_VERSION

# Download and extract MediaInfo source safely with CI-friendly wget progress
RUN wget --progress=dot:giga "https://mediaarea.net/download/binary/mediainfo/${MI_VERSION}/MediaInfo_CLI_${MI_VERSION}_GNU_FromSource.tar.xz" -O mediainfo_src.tar.xz && \
    tar -xf mediainfo_src.tar.xz

WORKDIR /MediaInfo_CLI_GNU_FromSource

# Compile with multi-core support to cut build time in half
RUN export MAKEFLAGS="-j$(nproc)" && \
    ./CLI_Compile.sh

# Strip debugging symbols. --strip-all is the correct standard for final executables.
RUN strip --strip-all MediaInfo/Project/GNU/CLI/mediainfo

# Use a scratch image to export ONLY the compiled binary back to the host
FROM scratch AS export-stage
COPY --from=builder /MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo /