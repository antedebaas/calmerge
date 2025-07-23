FROM python:3.13-slim as base
EXPOSE 3000
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    VIRTUAL_ENV=/venv \
    PATH="/venv/bin:$PATH"
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN groupadd --gid 10001 calmerge && \
    useradd --uid 10001 --gid calmerge --create-home --shell /bin/bash calmerge && \
    mkdir -p /app /venv && \
    chown -R calmerge:calmerge /app /venv
RUN pip install --no-cache-dir poetry==1.8.5
USER calmerge
WORKDIR /app
RUN python -m venv $VIRTUAL_ENV
COPY --chown=calmerge:calmerge pyproject.toml poetry.lock ./
RUN pip install --no-cache-dir --upgrade pip && \
    poetry install --only=main --no-root && \
    rm -rf $HOME/.cache/pypoetry
COPY --chown=calmerge:calmerge . .
RUN poetry install --only=main
RUN python -m compileall -q $VIRTUAL_ENV calmerge
RUN touch /app/calendars.toml && \
    chown calmerge:calmerge /app/calendars.toml
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:3000/health')" || exit 1
CMD ["calmerge", "serve"]
