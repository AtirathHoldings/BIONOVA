FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY . .

RUN chmod +x mvnw
RUN ./mvnw clean package -DskipTests

CMD ["sh","-c","java -Dserver.port=$PORT -jar target/bionova-backend-0.0.1-SNAPSHOT.jar"]