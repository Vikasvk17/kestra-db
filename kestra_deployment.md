# **Kestra Deployment Documentation**

## **1. Introduction**
This document outlines the deployment of **Kestra**, a data orchestration tool, using **Docker Compose** and **Amazon EKS**.

## **2. Deploying Kestra with Docker Compose**

### **2.1. Create the Required Files**

#### **Dockerfile (`kestra-db/Dockerfile`)**
```dockerfile
FROM kestra/kestra:v0.20.12

USER root
# Install required packages, download Oracle Instant Client, and unzip it
RUN apt-get update &&     apt-get install -y curl unzip &&     rm -rf /var/lib/apt/lists/* &&     curl -o /opt/oracle-instantclient.zip "https://download.oracle.com/otn_software/linux/instantclient/1926000/instantclient-basic-linux.x64-19.26.0.0.0dbru.zip" &&     cd /opt && unzip oracle-instantclient.zip

RUN apt-get update && apt-get install -y libaio1 && ldconfig
RUN apt-get update && apt-get install libaio-dev

ENV LD_LIBRARY_PATH=/opt/instantclient_19_26

RUN pip install --upgrade pip
RUN pip install oracledb==2.5.1 pandas==2.2.3 sqlalchemy==2.0.38 pymysql==1.1.1 pysolr==3.10.0 tqdm==4.67.1 cx_oracle==8.3.0 numpy==1.26.4 boto3==1.37.5

CMD ["server", "standalone"]
```

#### **Docker Compose File (`docker-compose.yml`)**
```yaml
version: '3.8'

volumes:
  postgres-data:
    driver: local
  kestra-data:
    driver: local

services:
  postgres:
    image: postgres:16
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: kestra
      POSTGRES_USER: kestra
      POSTGRES_PASSWORD: k3str4
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 10

  kestra:
    build: .
    user: "root"
    volumes:
      - kestra-data:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp/kestra-wd:/tmp/kestra-wd
    environment:
      KESTRA_CONFIGURATION: |
        datasources:
          postgres:
            url: jdbc:postgresql://postgres:5432/kestra
            driverClassName: org.postgresql.Driver
            username: kestra
            password: k3str4
        kestra:
          server:
            basicAuth:
              enabled: false
              username: "admin@kestra.io"
              password: kestra
          repository:
            type: postgres
          storage:
            type: local
            local:
              basePath: "/app/storage"
          queue:
            type: postgres
          tasks:
            tmpDir:
              path: /tmp/kestra-wd/tmp
          url: http://localhost:8080/
    ports:
      - "8080:8080"
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_healthy
```

### **2.2. Build and Run with Docker Compose**
```sh
cd /home/ubuntu/kestra-db
docker-compose build
docker-compose up -d
docker ps
```

---

## **3. Deploying Kestra on Amazon EKS**

### **3.1. Push Docker Image to AWS ECR**
```sh
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 009160051923.dkr.ecr.us-east-2.amazonaws.com
docker tag kestra-db_kestra 009160051923.dkr.ecr.us-east-2.amazonaws.com/kestra:latest
docker push 009160051923.dkr.ecr.us-east-2.amazonaws.com/kestra:latest
```

### **3.2. Deploy to Amazon EKS**

#### **Kestra Deployment (`kestra-deployment.yaml`)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kestra
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kestra
  template:
    metadata:
      labels:
        app: kestra
    spec:
      containers:
        - name: kestra
          image: 009160051923.dkr.ecr.us-east-2.amazonaws.com/kestra:latest
          ports:
            - containerPort: 8080
            - containerPort: 8081
          env:
            - name: KESTRA_CONFIGURATION
              value: |
                datasources:
                  postgres:
                    url: jdbc:postgresql://postgres:5432/kestra
                    driverClassName: org.postgresql.Driver
                    username: kestra
                    password: k3str4
                kestra:
                  server:
                    basicAuth:
                      enabled: false
                      username: "admin@kestra.io"
                      password: kestra
                  repository:
                    type: postgres
                  storage:
                    type: local
                    local:
                      basePath: "/app/storage"
                  queue:
                    type: postgres
                  tasks:
                    tmpDir:
                      path: /tmp/kestra-wd/tmp
                  url: http://localhost:8080/
```

#### **Kestra Service (`kestra-service.yaml`)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kestra
spec:
  selector:
    app: kestra
  type: LoadBalancer
  ports:
    - name: http
      port: 8080
      targetPort: 8080
    - name: grpc
      port: 8081
      targetPort: 8081
```

### **3.3. Deploy to Kubernetes**
```sh
kubectl apply -f kestra-deployment.yaml
kubectl apply -f kestra-service.yaml
```

### **3.4. Verify EKS Deployment**
```sh
kubectl get pods
kubectl get svc
```

### **3.5. Access Kestra UI**
```sh
http://a8774be45b2b44eef8c8b9dd381b432c-468344845.us-east-2.elb.amazonaws.com:8080
```

---

## **4. Conclusion**
- Initially deployed **Kestra** using **Docker Compose**.
- Migrated to **AWS EKS** for scalability.
- Successfully exposed Kestra UI via **AWS LoadBalancer**.

🚀 **Kestra is now fully deployed on AWS EKS!**
