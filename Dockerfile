FROM 2fic/whanos-javascript:latest

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

RUN npx tsc

EXPOSE 8080

CMD ["node", "app/app.js"]
