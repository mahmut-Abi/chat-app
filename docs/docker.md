# Docker 部署指南

本文档介绍如何使用 Docker 构建和部署 Chat App。

## 概述

项目提供了多阶段 Dockerfile，将 Flutter Web 应用打包为轻量级的 Nginx 镜像。

## 构建镜像

### 使用 Docker

```bash
# 构建镜像
docker build -t chat-app:latest .

# 运行容器
docker run -d -p 8080:80 --name chat-app chat-app:latest

# 查看日志
docker logs chat-app

# 停止容器
docker stop chat-app
docker rm chat-app
```

### 使用 Docker Compose

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 访问应用

容器启动后，在浏览器中访问：

```
http://localhost:8080
```

## 镜像说明

### 构建阶段

- **基础镜像**: `ghcr.io/cirruslabs/flutter:stable`
- **功能**: 构建 Flutter Web 应用
- **步骤**:
  1. 安装依赖 (`flutter pub get`)
  2. 运行代码生成 (`build_runner`)
  3. 构建 Web 应用 (`flutter build web`)

### 运行阶段

- **基础镜像**: `nginx:alpine`
- **大小**: ~50MB（不包含应用代码）
- **功能**: 提供静态文件服务
- **配置**: 自定义 Nginx 配置，支持 SPA 路由

## Nginx 配置

`docker/nginx.conf` 包含以下优化：

- **Gzip 压缩**: 压缩静态资源文件
- **缓存策略**: 
  - 静态资源（JS/CSS/图片）: 1年
  - HTML 文件: 禁止缓存
- **SPA 路由**: 所有路由请求都转发到 `index.html`

## GitHub Actions

项目在 CI/CD 中自动测试 Docker 构建：

- **构建测试**: 每次 push 或 PR 都会构建镜像
- **运行测试**: 启动容器并验证 HTTP 响应
- **缓存**: 使用 GitHub Actions 缓存加速构建
- **不推送**: 仅测试构建，不上传到镜像仓库

## 生产部署

### 环境变量

如果需要配置环境变量，可以在构建时传递：

```bash
docker build \
  --build-arg API_URL=https://api.example.com \
  -t chat-app:latest .
```

### 端口映射

默认容器暴露 80 端口，可以映射到任意主机端口：

```bash
docker run -d -p 3000:80 chat-app:latest
```

### 反向代理

建议在生产环境中使用反向代理（如 Nginx/Traefik）处理 HTTPS。

#### Nginx 反向代理示例

```nginx
server {
    listen 443 ssl http2;
    server_name chat.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 故障排查

### 构建失败

1. **确认 Docker 已安装并运行**
   ```bash
   docker --version
   docker ps
   ```

2. **检查构建日志**
   ```bash
   docker build --no-cache -t chat-app:latest .
   ```

3. **磁盘空间不足**
   ```bash
   docker system prune -a
   ```

### 容器启动失败

1. **查看容器日志**
   ```bash
   docker logs chat-app
   ```

2. **端口占用**
   ```bash
   # 检查端口是否被占用
   lsof -i :8080
   
   # 使用其他端口
   docker run -d -p 9000:80 chat-app:latest
   ```

3. **进入容器调试**
   ```bash
   docker exec -it chat-app sh
   ```

## 性能优化

- **多阶段构建**: 仅包含运行时所需文件
- **.dockerignore**: 排除不必要的文件，加速构建
- **Nginx Alpine**: 使用轻量级基础镜像
- **Gzip 压缩**: 减少传输大小
- **缓存策略**: 优化资源加载速度

## 相关文档

- [Dockerfile](../Dockerfile)
- [Docker Compose](../docker-compose.yml)
- [Nginx 配置](../docker/nginx.conf)
- [GitHub Actions](.github/workflows/flutter_test.yml)
