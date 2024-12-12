FROM 2fic/whanos-javascript:latest

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install
RUN npm install --save-dev typescript@4.4.3

# Copy the rest of the project files
COPY . .

# Compile TypeScript to JavaScript
RUN npx tsc

EXPOSE 8080

CMD ["node", "app/app.js"]
