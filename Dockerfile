FROM docker.io/2fic/whanos-javascript:latest
WORKDIR /app

# Copy package and lock files first to leverage build cache
COPY package*.json tsconfig.json ./

# Install dependencies
RUN npm install -g typescript@4.4.3
RUN npm install

# Now copy the remaining application files
COPY . .

# Confirm source files are in place
RUN ls -la /app
RUN ls -la /app/app

# Run the TypeScript compiler
RUN tsc
