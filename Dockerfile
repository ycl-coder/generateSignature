# 使用官方 Go 镜像作为构建环境
FROM golang:1.21-alpine AS builder

# 设置容器内工作目录（需与项目结构一致）
WORKDIR /app

# 启用 Go Modules 并设置国内代理
ENV GOPROXY=https://goproxy.cn,direct

# 复制依赖文件先执行下载（利用 Docker 缓存优化构建速度）
COPY go.mod go.sum ./
RUN go mod download

# 复制所有源代码到容器
COPY . .

# 编译生成二进制文件（CGO 禁用以适应 Alpine）
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/main .

# 使用轻量级运行时镜像
FROM alpine:3.19

# 设置容器内非 root 用户（提升安全性）
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 从构建阶段复制编译结果
COPY --from=builder --chown=appuser:appgroup /app/main /app/main

# 暴露微信云托管要求的端口（必须与发布配置一致）
EXPOSE 8080

# 启动应用（微信云托管要求前台运行）
CMD ["/app/main"]