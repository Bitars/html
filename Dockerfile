# Use the base image
FROM whanos-c

# Copy source code into the container
COPY . /app

# Build the application
RUN make

# Run the compiled program by default
CMD ["./compiled-app"]
