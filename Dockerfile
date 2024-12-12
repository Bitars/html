FROM 2fic/whanos-javascript

# Set working directory
WORKDIR /app

# Install TypeScript globally
RUN npm install -g typescript@4.4.3

# Compile TypeScript files
RUN if [ -f "tsconfig.json" ]; then tsc; else echo "No tsconfig.json found, skipping compilation."; fi

# Delete all .ts files except those in node_modules
RUN find . -name "*.ts" -type f -not -path "./node_modules/*" -delete

# Final placeholder CMD
CMD ["node", "app.js"]
