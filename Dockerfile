FROM localhost:5000/java-base


WORKDIR /app

COPY . .

RUN mvn clean package -f app/pom.xml

EXPOSE 8088

CMD ["java", "-jar", "app.jar"]