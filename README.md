# Solucao FIAP X - Infraestrutura EKS e Arquitetura do Sistema

## Integrantes - Grupo 250 do Hackathon FIAP
*   Thiago Frozzi Ramos - RM363916
*   Denise da Silva Ferreira - RM360753
*   Humberto Moura Feitoza - RM360753

---
## Video da apresentação do Hackathon

*   [Apresentação do Hackathon](https://youtu.be/1c8XJC5AvFo)

## Arquitetura do Sistema

O sistema foi concebido como uma plataforma de Processamento Distribuido de Videos, utilizando uma arquitetura orientada a eventos (Event-Driven) para garantir escalabilidade e resiliencia. A solucao roda em um cluster Amazon EKS (Kubernetes) e utiliza servicos gerenciados da AWS para persistencia e mensageria.

### Componentes Principais

#### 1. Entrada e Seguranca (Edge & Auth)
*   **API Gateway:** Ponto unico de entrada para todas as requisicoes externas.
*   **Auth Service (fiapx-app-auth):** Microsservico dedicado a autenticacao e autorizacao. Utiliza JWT para trafego seguro e Redis para gestao de sessoes e performance.

#### 2. Orquestracao e Upload (Core)
*   **Video API (fiapx-app-api):** Gerencia o ciclo de vida inicial do video. Recebe o upload, armazena o binario bruto no Amazon S3, registra metadados no PostgreSQL e dispara eventos de processamento.

#### 3. Processamento Assincrono (Worker)
*   **Worker Processor (fiapx-app-worker):** O componente de "heavy lifting". Consome mensagens do RabbitMQ, baixa o video do S3, realiza o processamento (extracao de imagens/frames) e gera um arquivo compactado (ZIP) de retorno.

#### 4. Camada de Dados e Mensageria
*   **Amazon RDS (PostgreSQL):** Banco de dados relacional para metadados de videos e usuarios.
*   **Amazon MQ (RabbitMQ):** Broker de mensagens para desacoplamento entre a API e o Worker.
*   **Amazon S3:** Storage de objetos para videos originais e arquivos processados.
*   **ElastiCache (Redis):** Cache de alta performance para o servico de autenticacao.

---

### Principais Endpoints da API

| Microsservico | Metodo | Rota | Descricao |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/auth/register` | Realiza o cadastro de um novo usuario. |
| **Auth** | `POST` | `/api/auth/login` | Autentica o usuario e retorna o token JWT. |
| **Video API** | `POST` | `/api/videos/upload` | Recebe um ou mais videos para processamento. |
| **Video API** | `GET` | `/api/videos/status` | Lista o status de todos os videos do usuario logado. |
| **Video API** | `POST` | `/api/videos/{id}/status` | Endpoint interno para atualizacao de status (usado pelo Worker). |

## SonarQube

*   [SonarQube](https://sonarcloud.io/projects?sort=name)
*   Cobertura de Testes:
![Cobertura de Testes](Cobertura-Sonar.png)

## Repositorios do Hackathon

### Infraestrutura
*   [Infra EKS (Kubernetes)](https://github.com/hackathom-fiap/fiapx-infra-eks)
*   [Infra Fila (AmazonMQ)](https://github.com/hackathom-fiap/fiapx-infra-amazonmq)
*   [Infra Database (PostgreSQL)](https://github.com/hackathom-fiap/fiapx-infra-postgres)
*   [Infra Redis](https://github.com/hackathom-fiap/fiapx-infra-redis)
*   [Infra IAM Roles](https://github.com/hackathom-fiap/fiapx-infra-roles)
*   [Infra GTW](https://github.com/hackathom-fiap/fiapx-infra-gtw)

### Microserviços (APIs)
*   [App Auth](https://github.com/hackathom-fiap/fiapx-app-auth)
*   [App Api](https://github.com/hackathom-fiap/fiapx-app-api)
*   [App Worker](https://github.com/hackathom-fiap/fiapx-app-worker)

---

### Diagrama de Arquitetura

```mermaid
graph TD
    %% Definicao de Estilos
    classDef client fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:white;
    classDef k8s fill:#326ce5,stroke:#fff,stroke-width:2px,color:white;
    classDef db fill:#336791,stroke:#fff,stroke-width:2px,color:white;
    classDef queue fill:#FF6600,stroke:#fff,stroke-width:2px,color:white;

    %% Atores
    User((Usuario))

    subgraph AWS [AWS Cloud]
        
        Gateway[API Gateway]:::aws
        
        subgraph EKS [EKS Cluster - Kubernetes]
            direction TB
            Auth[Auth Service]:::k8s
            API[Video API]:::k8s
            Worker[Worker Processor]:::k8s
        end

        subgraph Storage [Camada de Persistencia]
            S3[(Amazon S3)]:::aws
            subgraph RDS [Amazon RDS - PostgreSQL]
                DB_A[(auth_db)]:::db
                DB_API[(api-db)]:::db
            end
            Redis[(Redis)]:::db
        end

        subgraph Messaging [Mensageria]
            MQ[(RabbitMQ)]:::queue
        end
    end

    %% Fluxos
    User -->|1. Login / Upload| Gateway
    Gateway --> Auth
    Gateway --> API

    Auth -->|Valida Token| Redis
    Auth -->|Valida/Cria Usuario| DB_A
    API -->|2. Salva Video Bruto| S3
    API -->|3. Registra Metadados| DB_API
    API -->|4. Notifica Upload| MQ

    MQ -->|5. Consome Evento| Worker
    Worker -->|6. Processa Video| S3
    Worker -->|7. Atualiza Status via HTTP| API
    API -->|8. Persiste Status| DB_API
```

---

## Stack Tecnologica

*   **Linguagem:** Java 17
*   **Framework:** Spring Boot 3.2.2
*   **Seguranca:** Spring Security + JWT
*   **Infraestrutura:** Terraform (IaC), AWS EKS, Docker
*   **Mensageria:** RabbitMQ (Protocolo AMQP)
*   **Qualidade:** JaCoCo e SonarCloud

---

## Diferenciais da Solucao (Hackathon)

1.  **Escalabilidade Horizontal:** O Worker Processor pode ser escalado independentemente da API (usando K8s HPA) conforme a fila do RabbitMQ cresce.
2.  **Arquitetura Hexagonal:** O uso de Ports and Adapters na Video API permite trocar o banco de dados ou o provider de nuvem com minimo impacto.
3.  **Seguranca Stateless:** Toda a comunicacao e protegida por JWT, eliminando a necessidade de manter estado de sessao no servidor da API.
4.  **Resiliencia:** Se o Worker falhar, a mensagem volta para a fila, garantindo que nenhum video deixe de ser processado.

---
