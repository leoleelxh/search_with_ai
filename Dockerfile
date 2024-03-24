# 使用 Node.js 作为基础镜像
FROM node:18

# 设置工作目录
WORKDIR /app

# 复制项目文件到工作目录
COPY . /app

# 安装服务端依赖并构建
RUN yarn install && yarn run build

# 安装前端依赖并构建
RUN cd web && yarn install && yarn run build

# 暴露端口（根据项目实际使用的端口进行修改）
EXPOSE 3210

# 启动应用程序
CMD ["yarn", "run", "start"]