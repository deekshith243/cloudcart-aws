FROM node:20-alpine AS build
WORKDIR /workspace/backend
COPY backend/package*.json ./
COPY package.json /workspace/package.json
RUN npm ci
COPY backend/tsconfig.json backend/eslint.config.js backend/prisma.config.ts ./
COPY backend/prisma ./prisma
RUN DATABASE_URL=postgresql://build:build@localhost:5432/build npx prisma generate
COPY backend/src ./src
RUN npm run build

FROM build AS migration
CMD ["npx", "prisma", "migrate", "deploy"]

FROM node:20-alpine
WORKDIR /workspace/backend
ENV NODE_ENV=production
ENV PORT=4000
COPY backend/package*.json ./
COPY package.json /workspace/package.json
RUN npm ci --omit=dev
COPY --from=build /workspace/backend/dist ./dist
COPY --from=build /workspace/backend/node_modules/.prisma ./node_modules/.prisma
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget --spider -q "http://127.0.0.1:${PORT}/health" || exit 1
CMD ["node", "dist/server.js"]
