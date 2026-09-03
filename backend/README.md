# KRIPTA Backend

Backend da aplicacao KRIPTA - Projeto de TCC.

## Tecnologias

- Java 21 LTS
- Spring Boot 3.4.2
- Maven 3.9+

## Requisitos

- **Java 21 LTS** (o projeto nao e compativel com versoes diferentes)
- **Maven 3.9+**

## Compilacao

```bash
mvn clean compile
```

## Execucao

```bash
mvn spring-boot:run
```

A aplicacao iniciara na porta **8080**.

## Testes

```bash
mvn clean test
```

Build completo (compilacao + testes + empacotamento):

```bash
mvn clean package
```

## Endpoint de Health

Verificar se a API esta funcionando:

```
GET http://localhost:8080/api/health
```

Resposta esperada:

```json
{
  "status": "UP",
  "service": "KRIPTA Backend",
  "message": "API esta funcionando corretamente"
}
```
