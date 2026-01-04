# Development Dockerfile for React frontend
# Builds dependencies and runs the dev server (npm start).
# This is intended for local development. For faster iteration, use a
# docker-compose service with a bind mount for the source directory.

FROM node:18-alpine

WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH

# Install dependencies (use package-lock.json if present)
COPY package.json package-lock.json* ./
RUN npm ci --silent

# Copy all source files
COPY . .

# Expose the typical React dev server port (adjust if your app uses a different PORT)
ENV PORT=3000
EXPOSE 3000

# Default command runs the dev server. It will pick up changes when files are mounted from the host.
CMD ["npm", "start"]
