# Start from the official Node.js image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package files first (Docker caches this layer)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your app
COPY . .

# Expose the port your app listens on
EXPOSE 3001

# Command to start the app
CMD ["node", "index.js"]