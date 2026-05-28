# Use Ubuntu as base image
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    lua5.3 \
    redis-server \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy application files
COPY . /app/

# Install frontend dependencies
WORKDIR /app/frontend
RUN npm install

# Go back to root
WORKDIR /app

# Expose ports
EXPOSE 8080 3000

# Start Redis and the application
CMD redis-server --daemonize yes && lua backend/pure_lua_server.lua
