# Frontend (React / CRA) Dockerfile
FROM node:20-alpine AS base
WORKDIR /app

# Install deps separately for better caching
COPY package.json package-lock.json ./
RUN npm ci

# Copy source
COPY . .

# Expose dev port
EXPOSE 3003

# Default environment for dev
ENV HOST=0.0.0.0 \
    PORT=3003

# Dev: start with react-scripts. For prod, override to `npm run build` and serve with nginx or similar
CMD ["npm", "start"]
