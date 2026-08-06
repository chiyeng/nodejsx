# NodeJS Argo 项目部署指南

本项目是一个基于 Node.js 的 Web 服务，支持使用 Docker 进行容器化部署。

## 部署方式

### 方式一：使用 Docker Compose 部署（推荐）

1. 确保已安装 Docker 和 Docker Compose。
2. 在项目根目录下运行以下命令启动服务：
   ```bash
   docker-compose up -d
   ```
3. 服务启动后，可以通过 `http://localhost:3000` 访问。

### 方式二：使用 Docker 部署

1. 构建 Docker 镜像：
   ```bash
   docker build -t nodejs-argo .
   ```
2. 运行 Docker 容器：
   ```bash
   docker run -d -p 3000:3000 --name nodejs-argo-container nodejs-argo
   ```

### 方式三：本地直接运行

1. 安装依赖：
   ```bash
   npm install
   ```
2. 启动服务：
   ```bash
   npm start
   ```
