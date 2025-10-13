# 多阶段构建 Flutter Web 应用
# 阶段 1: 构建阶段
FROM ghcr.io/cirruslabs/flutter:stable AS builder

# 设置工作目录
WORKDIR /app

# 复制 pubspec 文件并获取依赖
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 复制整个项目
COPY . .

# 运行代码生成
RUN flutter pub run build_runner build --delete-conflicting-outputs

# 构建 Web 应用
RUN flutter build web --release

# 阶段 2: 运行阶段
FROM nginx:alpine

# 复制构建产物到 nginx
COPY --from=builder /app/build/web /usr/share/nginx/html

# 复制 nginx 配置
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]
