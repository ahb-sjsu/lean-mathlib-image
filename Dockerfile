# A Lean 4 toolchain and a prebuilt Mathlib (the official cache), for compiling projects that depend on Mathlib
# without building Mathlib first. The image holds no project code.
#
#   /opt/lean/toolchain           the Lean toolchain (bin/lean, lib/lean)
#   /opt/lean/packages/<name>/    each dependency's .lake/build/lib/lean (compiled .olean files) and its LICENSE
#   /opt/lean/lake-manifest.json  the exact dependency revisions
#
# Build arguments pin the Lean release and the Mathlib commit; the dependency revisions follow Mathlib's own
# manifest at that commit (lake update), so one (LEAN, MATHLIB) pair always yields the same environment.

FROM debian:bookworm-slim AS build
ARG LEAN=v4.33.1
ARG MATHLIB=0df444a360eaa60ab8c11dca51a86af692955474
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git zstd \
 && rm -rf /var/lib/apt/lists/*
RUN curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o /tmp/elan-init.sh \
 && sh /tmp/elan-init.sh -y --no-modify-path --default-toolchain "leanprover/lean4:${LEAN}"
ENV PATH=/root/.elan/bin:$PATH
WORKDIR /ws
RUN printf 'name = "ws"\n\n[[require]]\nname = "mathlib"\ngit = "https://github.com/leanprover-community/mathlib4"\nrev = "%s"\n' \
      "$MATHLIB" > lakefile.toml \
 && echo "leanprover/lean4:${LEAN}" > lean-toolchain \
 && lake update \
 && lake exe cache get
# keep only what compiling against Mathlib needs: each package's compiled library and its license
RUN set -e; mkdir -p /out/packages; \
    for p in .lake/packages/*; do \
      n=$(basename "$p"); \
      if [ -d "$p/.lake/build/lib/lean" ]; then \
        mkdir -p "/out/packages/$n/.lake/build/lib"; \
        cp -a "$p/.lake/build/lib/lean" "/out/packages/$n/.lake/build/lib/"; \
        for f in LICENSE LICENSE.md COPYING; do [ -f "$p/$f" ] && cp "$p/$f" "/out/packages/$n/"; done; \
      fi; \
    done; \
    cp lake-manifest.json lean-toolchain lakefile.toml /out/; \
    cp -a "$(readlink -f /root/.elan/toolchains/leanprover--lean4---${LEAN})" /out/toolchain; \
    du -sh /out/toolchain /out/packages

FROM debian:bookworm-slim
ARG LEAN=v4.33.1
ARG MATHLIB=0df444a360eaa60ab8c11dca51a86af692955474
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates python3 python3-pip zstd \
 && rm -rf /var/lib/apt/lists/* \
 && pip3 install --no-cache-dir --break-system-packages "nats-py>=2.6"
COPY --from=build /out /opt/lean
ENV PATH=/opt/lean/toolchain/bin:$PATH \
    LEAN_TOOLCHAIN=/opt/lean/toolchain \
    LEAN_PACKAGES=/opt/lean/packages \
    LEAN_VERSION=${LEAN} \
    MATHLIB_REV=${MATHLIB}
LABEL org.opencontainers.image.source="https://github.com/ahb-sjsu/lean-mathlib-image" \
      org.opencontainers.image.description="Lean ${LEAN} toolchain with prebuilt Mathlib ${MATHLIB}" \
      org.opencontainers.image.licenses="Apache-2.0 AND MIT"
