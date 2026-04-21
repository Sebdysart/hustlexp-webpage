# MODIFIED: replaces pierrezemb/gostatic with nginx:1.27-alpine so that
# unknown routes fall back to index.html (SPA routing). Without this,
# /survey, /thanks, /ops all 404 on direct hit and browser refresh.
#
# Two-stage build: node builds the Vite bundle, nginx serves /dist.

# --- build stage ---
FROM node:18-alpine AS builder
WORKDIR /app

# Install only runtime deps first for better layer caching.
COPY package*.json ./
RUN npm ci --no-audit --no-fund

# Build-time env (Vite inlines VITE_* at build time).
# Pass through Fly with `fly deploy --build-arg VITE_SUPABASE_URL=... ...`
# or set in fly.toml [build.args]. Defaults keep the legacy flow working
# even if new vars aren't provided.
#
# NOTE: VITE_FIREBASE_* are declared here as explicit ARGs because the
# .dockerignore excludes all .env files from the Docker context — without
# these ARGs, a remote-only build bakes empty strings into Firebase config
# and the legacy waitlist on / breaks silently (CRAFT-2 regression).
ARG VITE_FIREBASE_API_KEY=""
ARG VITE_FIREBASE_AUTH_DOMAIN=""
ARG VITE_FIREBASE_PROJECT_ID=""
ARG VITE_FIREBASE_STORAGE_BUCKET=""
ARG VITE_FIREBASE_MESSAGING_SENDER_ID=""
ARG VITE_FIREBASE_APP_ID=""
ARG VITE_FIREBASE_MEASUREMENT_ID=""
ARG VITE_SUPABASE_URL=""
ARG VITE_SUPABASE_ANON_KEY=""
ARG VITE_TALLY_FORM_CUSTOMER=""
ARG VITE_TALLY_FORM_HUSTLER=""
ARG VITE_TALLY_FORM_WAITLIST=""
ARG VITE_CONSENT_VERSION="v1"
ARG VITE_GO_LIVE_THRESHOLD="25"
ARG VITE_BACKEND_OPS_ENDPOINT=""
ARG VITE_GA4_MEASUREMENT_ID=""
ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY \
    VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN \
    VITE_FIREBASE_PROJECT_ID=$VITE_FIREBASE_PROJECT_ID \
    VITE_FIREBASE_STORAGE_BUCKET=$VITE_FIREBASE_STORAGE_BUCKET \
    VITE_FIREBASE_MESSAGING_SENDER_ID=$VITE_FIREBASE_MESSAGING_SENDER_ID \
    VITE_FIREBASE_APP_ID=$VITE_FIREBASE_APP_ID \
    VITE_FIREBASE_MEASUREMENT_ID=$VITE_FIREBASE_MEASUREMENT_ID \
    VITE_SUPABASE_URL=$VITE_SUPABASE_URL \
    VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY \
    VITE_TALLY_FORM_CUSTOMER=$VITE_TALLY_FORM_CUSTOMER \
    VITE_TALLY_FORM_HUSTLER=$VITE_TALLY_FORM_HUSTLER \
    VITE_TALLY_FORM_WAITLIST=$VITE_TALLY_FORM_WAITLIST \
    VITE_CONSENT_VERSION=$VITE_CONSENT_VERSION \
    VITE_GO_LIVE_THRESHOLD=$VITE_GO_LIVE_THRESHOLD \
    VITE_BACKEND_OPS_ENDPOINT=$VITE_BACKEND_OPS_ENDPOINT \
    VITE_GA4_MEASUREMENT_ID=$VITE_GA4_MEASUREMENT_ID

COPY . .
RUN npm run build

# --- runtime stage ---
FROM nginx:1.27-alpine

# SPA fallback + safe caching defaults.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Built assets.
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 8043
CMD ["nginx", "-g", "daemon off;"]
