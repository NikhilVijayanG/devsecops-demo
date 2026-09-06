# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:1.31-alpine

# Apply outstanding Alpine security patches. The upstream nginx:alpine image is
# rebuilt on nginx releases, not on every apk security update, so it ships
# packages that already have fixes available (e.g. util-linux/libuuid). Without
# this the Trivy gate in CI fails on fixable HIGH CVEs.
#
# BUILD_REV changes every CI run so this layer is never served from a stale
# build cache -- otherwise a rebuild would replay yesterday's packages and the
# scan could never recover from a newly published CVE.
ARG BUILD_REV=local
RUN echo "build-rev: ${BUILD_REV}" > /dev/null && apk --no-cache upgrade

COPY --from=build /app/dist /usr/share/nginx/html
# Add nginx configuration if needed
# COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]