# Stage 1: 构建 node_modules（含 canvas 编译）
FROM node:16-bullseye as deps

WORKDIR /app
COPY package.json yarn.lock ./
RUN sed -i 's|http://deb.debian.org/debian|http://mirrors.aliyun.com/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://deb.debian.org/debian-security|http://mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libcairo2-dev \
    libjpeg-dev \
    libpango1.0-dev \
    libgif-dev \
    librsvg2-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*
RUN npm config set registry https://repo.huaweicloud.com/repository/npm/
RUN yarn install --frozen-lockfile

# Stage 2: 运行阶段镜像，复用依赖并安装必要系统库
FROM node:16-bullseye

WORKDIR /app
RUN sed -i 's|http://deb.debian.org/debian|http://mirrors.aliyun.com/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://deb.debian.org/debian-security|http://mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcairo2 \
    libjpeg62-turbo \
    libpango-1.0-0 \
    libgif-dev \
    librsvg2-2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./
COPY yarn.lock ./
COPY static ./static


EXPOSE 1234
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:1234/ || exit 1

CMD ["yarn", "start"]
