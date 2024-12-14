FROM 2fic/whanos-javascript:latest

RUN npm config set registry https://registry.yarnpkg.com/

RUN npm config set fetch-retry-mintimeout 20000
RUN npm config set fetch-retry-maxtimeout 120000

WORKDIR /app

COPY package.json package-lock.json ./
RUN for i in 1 2 3; do \
    npm install && break || \
    (echo "Retrying npm install in 5 seconds..." && sleep 5); \
done

RUN for i in 1 2 3; do \
    npm install --save-dev typescript@4.4.3 && break || \
    (echo "Retrying npm install in 5 seconds..." && sleep 5); \
done

COPY . .

RUN npx tsc

EXPOSE 3000

CMD ["node", "app/app.js"]
