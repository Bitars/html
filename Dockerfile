FROM 2fic/whanos-javascript:latest

RUN npm config set registry https://registry.npmjs.org/

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

RUN npm install --save-dev typescript@4.4.3 || \
    (echo "Retrying npm install..." && sleep 5 && npm install --save-dev typescript@4.4.3)

COPY . .


EXPOSE 8080

CMD ["node", "app/app.js"]
