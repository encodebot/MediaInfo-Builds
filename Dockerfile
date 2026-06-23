FROM debian:forky-slim AS builder

# Enforce Strict Error Handling. Instantly Aborts On Any Hidden Failure.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set Non-Interactive Frontend For Apt To Prevent Hanging Prompts.
ENV DEBIAN_FRONTEND=noninteractive
# Accept MediaInfo Version As A Dynamic Build Argument.
ARG MI_VERSION
# Intentionally Omit Extra Libraries To Ensure The Binary Remains Highly Portable.
# 1. Install Prerequisites Required For MediaInfo Compilation.
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

# 2. Download & Extract Mediainfo Source Safely With CI-Friendly wget Progress.
RUN wget --progress=dot:giga "https://mediaarea.net/download/binary/mediainfo/${MI_VERSION}/MediaInfo_CLI_${MI_VERSION}_GNU_FromSource.tar.xz" -O mediainfo_src.tar.xz && \
    tar -xf mediainfo_src.tar.xz

WORKDIR /MediaInfo_CLI_GNU_FromSource

# 3. Compile With Multi-Core Support To Cut Build Time In Half.
RUN export MAKEFLAGS="-j$(nproc)" && \
    ./CLI_Compile.sh

# 4. Strip Debugging Symbols From The Actual Binaries To Shrink The Final Size.
RUN strip --strip-all MediaInfo/Project/GNU/CLI/mediainfo

# 5. Use A Scratch Image To Export ONLY The Portable Directory Structure Back To The Host.
FROM scratch AS export-stage
COPY --from=builder /MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo /