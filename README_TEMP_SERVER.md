# 临时认证服务器使用说明

这是一个为Flutter应用提供临时登录和数据服务的Node.js Express服务器，使用SQLite3数据库存储数据。

## 功能特性

- ✅ 用户注册 (`POST /user/register`)
- ✅ 用户登录 (`POST /user/login`)
- ✅ JWT令牌验证 (`GET /user/verify`)
- ✅ 用户登出 (`POST /user/logout`)
- ✅ 获取用户信息 (`GET /user/profile`)
- ✅ 获取积分排行 (`GET /statistics/pointsranking`)
- ✅ 获取积分分布 (`GET /points/distribution`)
- ✅ 获取用户总积分 (`GET /points/total`)
- ✅ 获取轮播书籍 (`GET /carouse/get`)
- ✅ 获取书籍列表 (`GET /carouse/list`)
- ✅ 获取每日任务 (`GET /points/DailyTask`)
- ✅ 签到功能 (`GET /points/signin`)
- ✅ 兑换商品 (`POST /exchange`)
- ✅ 健康检查 (`GET /health`)
- ✅ CORS支持
- ✅ 密码加密存储
- ✅ SQLite3数据库持久化
- ✅ 错误处理

## 数据库结构

服务器使用SQLite3数据库，包含以下表：

- **users** - 用户表（用户名、密码、昵称等）
- **friend_ranking** - 积分排行表
- **points_distribution** - 积分分布表
- **books** - 书籍表（轮播和列表）
- **daily_tasks** - 每日任务表
- **products** - 商品兑换表

## 安装和运行

### 1. 安装依赖

```bash
npm install
```

### 2. 启动服务器

```bash
# 生产模式
npm start

# 开发模式（自动重启）
npm run dev

# 智能启动（自动查找可用端口）
npm run start:smart
```

服务器将在 `http://localhost:8080` 启动

### 3. 测试服务器

```bash
# 基础测试
npm test

# 全面API测试
npm run test:all
```

## API接口说明

### 用户认证相关

#### 用户注册
```
POST /user/register
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123"
}
```

#### 用户登录
```
POST /user/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123"
}
```

#### 验证令牌
```
GET /user/verify
Headers: {
  "token": "your-jwt-token"
}
```

#### 获取用户信息
```
GET /user/profile
Headers: {
  "token": "your-jwt-token"
}
```

### 数据接口

#### 获取积分排行
```
GET /statistics/pointsranking
Headers: {
  "token": "your-jwt-token"
}
```

#### 获取积分分布
```
GET /points/distribution
Headers: {
  "token": "your-jwt-token"
}
```

#### 获取用户总积分
```
GET /points/total
Headers: {
  "token": "your-jwt-token"
}
```

#### 获取轮播书籍
```
GET /carouse/get
Headers: {
  "token": "your-jwt-token"
}
```

#### 获取书籍列表
```
GET /carouse/list
Headers: {
  "token": "your-jwt-token"
}
```

#### 获取每日任务
```
GET /points/DailyTask
Headers: {
  "token": "your-jwt-token"
}
```

#### 签到
```
GET /points/signin
Headers: {
  "token": "your-jwt-token"
}
```

#### 兑换商品
```
POST /exchange
Headers: {
  "token": "your-jwt-token"
}
Content-Type: application/json

{
  "productId": 1
}
```

## Flutter应用配置

已经将Flutter应用中的API基础URL修改为：
```dart
// 登录API
static const String _baseUrl = 'http://10.0.2.2:8080';

// 其他API
baseUrl: 'http://10.0.2.2:8080',
```

## 默认数据

服务器启动时会自动插入以下默认数据：

### 测试账号
- **用户名**: `testuser`
- **密码**: `TestPass123`

### 积分排行（5个用户）
- 张三 - 1250分
- 李四 - 980分
- 王五 - 756分
- 赵六 - 650分
- 孙七 - 520分

### 积分分布（4个分类）
- 学习任务 - 450分 (36.0%)
- 运动健康 - 320分 (25.6%)
- 社交互动 - 280分 (22.4%)
- 其他活动 - 200分 (16.0%)

### 红色文化书籍（5本）
- 红色记忆（轮播）
- 长征路上（轮播）
- 红色文化
- 革命故事
- 红色教育

### 每日任务（5个）
- 每日签到 - 10分
- 阅读文章 - 20分
- 运动打卡 - 15分
- 分享心得 - 25分
- 知识问答 - 30分

### 兑换商品（4个）
- 红色文化T恤 - 500积分
- 纪念徽章 - 300积分
- 红色书籍 - 800积分
- 纪念水杯 - 400积分

## 注意事项

1. **数据持久化**: 使用SQLite3数据库，数据会持久保存
2. **安全性**: 这是一个临时服务器，生产环境请使用更安全的配置
3. **JWT密钥**: 请在生产环境中更改 `JWT_SECRET`
4. **网络访问**: 如果需要在真机上测试，请将localhost改为本机IP地址
5. **数据库文件**: 数据库文件为 `temp_auth.db`，位于项目根目录

## 故障排除

1. **端口被占用**: 使用 `npm run start:smart` 自动查找可用端口
2. **CORS错误**: 确保Flutter应用和服务器在同一网络环境
3. **连接失败**: 检查防火墙设置和网络连接
4. **数据库错误**: 删除 `temp_auth.db` 文件重新初始化

## 恢复原服务器

当原服务器恢复后，请将Flutter应用中的API基础URL改回：
```dart
// 登录API
static const String _baseUrl = 'http://81.71.152.77:8080';

// 其他API
baseUrl: 'http://81.71.152.77:8080',
```
