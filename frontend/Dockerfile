# syntax=docker/dockerfile:1
# check=error=true

# Builds the SPA and serves the static bundle with nginx. Kamal builds this image
# (see config/deploy.yml) and puts its proxy in front to terminate TLS, so nginx
# itself only ever listens on plain HTTP inside the container.
#
# Build locally with the API origin baked in:
#   docker build --build-arg VITE_API_URL=https://api.example.com -t frontend .

FROM node:24-alpine AS build
WORKDIR /app

# Dependencies first, so a source-only change reuses this layer.
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Vite inlines import.meta.env.VITE_API_URL at build time, so this must arrive as a
# build argument rather than at runtime (see src/api/client.js).
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

FROM nginx:alpine AS serve
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
