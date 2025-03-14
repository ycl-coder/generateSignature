# 使用官方 Go 镜像（Alpine 版更轻量）
FROM golang:1.21-alpine AS builder

# 设置容器内工作目录（与项目根目录对应）
WORKDIR /app

RUN if [ ! -f go.sum ]; then touch go.sum; fi

# 复制依赖文件（利用 Docker 缓存层加速构建）
COPY go.mod go.sum ./

RUN if [ ! -s go.sum ]; then go mod tidy; fi

# 设置国内代理加速依赖下载（解决 go mod download 超时问题）
ENV GOPROXY=https://goproxy.cn,direct

# 下载依赖（保留 mod 文件校验）
RUN go mod download && go mod verify

# 复制全部项目文件到容器（排除 .dockerignore 中的文件）
COPY . .

# 编译项目（指定输出文件名为 main，兼容不同入口路径）
RUN go build -o main ./app/main.go  # 若主文件在 app 目录则改为 ./app/main.go

# --- 多阶段构建：减小镜像体积 ---
FROM alpine:3.18

# 设置非 root 用户（增强安全性）
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 从构建阶段复制二进制文件
COPY --from=builder --chown=appuser:appgroup /app/main /app/main

# 暴露应用端口（根据实际端口调整）
EXPOSE 8080

# 启动应用（前台运行避免容器退出）
ENTRYPOINT ["/app/main"]