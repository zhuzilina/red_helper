# 红色文化助手后端服务器

这是一个基于Express.js和SQLite3的现代化后端服务器，为红色文化助手Flutter应用提供API服务。

## 🚀 功能特性

- ✅ **用户认证系统** - JWT令牌认证，支持注册、登录、令牌验证
- ✅ **积分系统** - 用户积分管理，积分排行，积分分布统计
- ✅ **每日任务** - 任务管理，签到功能
- ✅ **书籍管理** - 红色文化书籍展示，轮播图支持
- ✅ **商品兑换** - 积分兑换商品，库存管理
- ✅ **数据统计** - 好友排行，积分分布图表数据
- ✅ **安全防护** - 请求限制，输入验证，错误处理
- ✅ **日志系统** - 完整的操作日志记录
- ✅ **数据库管理** - SQLite3数据库，自动初始化

## 📁 项目结构

```
server/
├── src/
│   ├── app.js                 # 主应用文件
│   ├── routes/                # 路由文件
│   │   ├── auth.js           # 认证路由
│   │   ├── user.js           # 用户路由
│   │   ├── statistics.js     # 统计路由
│   │   ├── points.js         # 积分路由
│   │   ├── carousel.js       # 轮播图路由
│   │   └── exchange.js       # 兑换路由
│   ├── middleware/            # 中间件
│   │   ├── authMiddleware.js # 认证中间件
│   │   └── errorMiddleware.js # 错误处理中间件
│   ├── database/             # 数据库相关
│   │   ├── connection.js     # 数据库连接
│   │   └── init.js          # 数据库初始化
│   └── utils/                # 工具函数
│       └── logger.js         # 日志工具
├── data/                     # 数据库文件目录
├── logs/                     # 日志文件目录
├── package.json              # 项目配置
├── env.example              # 环境变量示例
└── README.md                # 项目文档
```

## 🛠️ 安装和运行

### 1. 安装依赖

```bash
cd server
npm install
```

### 2. 配置环境变量

复制环境变量示例文件并修改：

```bash
cp env.example .env
```

编辑 `.env` 文件，配置必要的环境变量：

```env
# 服务器配置
PORT=8080
NODE_ENV=development

# JWT配置
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

# 数据库配置
DB_PATH=./data/red_helper.db

# 安全配置
BCRYPT_ROUNDS=10
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS配置
CORS_ORIGIN=http://localhost:3000,http://192.168.137.1:3000

# 日志配置
LOG_LEVEL=info
```

### 3. 启动服务器

```bash
# 开发模式（自动重启）
npm run dev

# 生产模式
npm start
```

### 4. 数据库管理

```bash
# 初始化数据库
npm run db:migrate

# 插入测试数据
npm run db:seed

# 重置数据库
npm run db:reset
```

## 📡 API接口

### 认证接口

- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/verify` - 验证令牌

### 用户接口

- `GET /api/user/profile` - 获取用户信息
- `PUT /api/user/profile` - 更新用户信息
- `GET /api/user/points` - 获取用户积分

### 统计接口

- `GET /api/statistics/pointsranking` - 获取积分排行

### 积分接口

- `GET /api/points/distribution` - 获取积分分布
- `GET /api/points/total` - 获取用户总积分
- `GET /api/points/DailyTask` - 获取每日任务
- `GET /api/points/signin` - 签到功能

### 轮播图接口

- `GET /api/carousel/get` - 获取轮播书籍
- `GET /api/carousel/list` - 获取书籍列表

### 兑换接口

- `POST /api/exchange` - 兑换商品
- `GET /api/exchange/records` - 获取兑换记录

## 🔧 开发工具

### 代码检查

```bash
# 检查代码规范
npm run lint

# 自动修复代码规范问题
npm run lint:fix
```

### 测试

```bash
# 运行测试
npm test

# 监听模式运行测试
npm run test:watch
```

## 📊 数据库结构

### 主要数据表

- **users** - 用户信息表
- **friend_ranking** - 好友排行榜表
- **points_distribution** - 积分分布表
- **books** - 书籍信息表
- **daily_tasks** - 每日任务表
- **products** - 商品信息表
- **sign_in_records** - 签到记录表
- **exchange_records** - 兑换记录表

## 🔒 安全特性

- **JWT认证** - 基于令牌的身份验证
- **密码加密** - bcrypt密码哈希
- **输入验证** - express-validator输入验证
- **请求限制** - 防止暴力攻击
- **CORS配置** - 跨域请求控制
- **安全头** - Helmet安全中间件
- **错误处理** - 统一的错误处理机制

## 📝 日志系统

服务器使用Winston日志库，支持：

- 控制台日志输出
- 文件日志记录
- 错误日志分离
- 日志级别控制
- 日志轮转

## 🚀 部署

### 生产环境部署

1. 设置环境变量 `NODE_ENV=production`
2. 配置生产环境的JWT密钥
3. 设置适当的CORS配置
4. 配置日志级别
5. 使用PM2或类似工具管理进程

### Docker部署

```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
```

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 📄 许可证

MIT License




