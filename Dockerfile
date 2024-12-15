# Use the base image from the local registry
FROM localhost:5000/whanos-c:latest

# Copy source code into the container
COPY . /app

# Build the application
WORKDIR /app
RUN make

# Run the compiled program by default
CMD ["./compiled-app"]
