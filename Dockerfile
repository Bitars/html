# Standalone Dockerfile for building and running the C project

FROM gcc:13.2

# Set the working directory inside the container
WORKDIR /app

# Copy the project files into the container
COPY . .

# Build the project using the Makefile
RUN make

# Clean unnecessary files after the build
RUN make clean

# Command to run the compiled application
CMD ["./compiled-app"]
