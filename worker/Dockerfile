FROM node:20-alpine AS build
WORKDIR /workspace/worker
COPY worker/package*.json ./
COPY package.json /workspace/package.json
RUN npm ci
COPY worker/tsconfig.json worker/eslint.config.js ./
COPY worker/src ./src
RUN npm run build

FROM node:20-alpine
WORKDIR /workspace/worker
ENV NODE_ENV=production
COPY worker/package*.json ./
COPY package.json /workspace/package.json
RUN npm ci --omit=dev
COPY --from=build /workspace/worker/dist ./dist
CMD ["node", "dist/worker.js"]
