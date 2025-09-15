ARG PYTHON_VERSION=3.13

FROM astral/uv:0.8.17 AS uvbuild
FROM debian:latest

ARG PYTHON_VERSION

COPY --from=uvbuild uv /bin/uv

ENV PATH="$PATH:/root/.local/bin"

USER root

RUN --mount=type=bind,dst=/tmp/context \
  uv venv && \
  uv python install --no-cache ${PYTHON_VERSION} && \
  uv pip install --no-cache -r /tmp/context/requirements.txt

ENTRYPOINT ["uv", "run", "marimo", "edit", "--no-token", "--host", "0.0.0.0", "--port", "8080"]
