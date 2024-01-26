# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

ARG NODE_VERSION=18.0.0

FROM node:${NODE_VERSION}-alpine as base

WORKDIR /usr/src/app

# Expose the port that the application listens on.
EXPOSE 3000

# - - -
# For development
FROM base as dev

RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev

USER node

COPY . .

CMD npm run dev

# - - -
# For production
FROM base as prod

# Use production node environment by default.
ENV NODE_ENV production

# Dockerのキャッシュを利用するために、依存関係を別ステップとしてダウンロードする。
# 以降のビルドを高速化するために、/root/.npmへのキャッシュマウントを活用する。
# package.jsonとpackage-lock.jsonをこのレイヤーにコピーする手間を省くために、 
# package.jsonとpackage-lock.jsonへのバインドマウントを活用する。
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# Run the application as a non-root user.
USER node

# Copy the rest of the source files into the image.
COPY . .

# Run the application.
CMD node src/index.js

# For TEST
FROM base as test
ENV NODE_ENV test
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
RUN npm run test