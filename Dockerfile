# Dockerfile
FROM node:20-bullseye-slim

# Install LibreOffice and utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libreoffice-core libreoffice-writer libreoffice-impress libreoffice-common \
      libreoffice-java-common libreoffice-calc libreoffice-draw \
      poppler-utils \
      imagemagick \
      qpdf \
      ca-certificates \
      wget \
      fonts-dejavu-core \
      gzip \
      unzip \
      ttf-mscorefonts-installer --no-install-recommends || true && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash appuser
WORKDIR /home/appuser
USER appuser

# Copy app
COPY --chown=appuser:appuser package.json package-lock.json ./
RUN npm ci --production

COPY --chown=appuser:appuser . .

ENV NODE_ENV=production
ENV TMPDIR=/home/appuser/tmp
RUN mkdir -p /home/appuser/tmp && chmod 700 /home/appuser/tmp

# Healthcheck uses soffice --version to ensure binary available (runs as non-root)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD soffice --version | grep "LibreOffice" || exit 1

CMD ["node", "worker.js"]
