const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const logger = require('../utils/logger');

// 确保数据目录存在
const dataDir = path.join(__dirname, '../../data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// 数据库文件路径
const dbPath = process.env.DB_PATH || path.join(dataDir, 'red_helper.db');

// 创建数据库连接
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    logger.error('数据库连接失败:', err);
    process.exit(1);
  }
  logger.info(`数据库连接成功: ${dbPath}`);
});

// 启用外键约束
db.run('PRAGMA foreign_keys = ON');

// 数据库连接池配置
db.configure('busyTimeout', 3000);

// 优雅关闭数据库连接
process.on('SIGINT', () => {
  db.close((err) => {
    if (err) {
      logger.error('关闭数据库连接时出错:', err);
    } else {
      logger.info('数据库连接已关闭');
    }
    process.exit(0);
  });
});

module.exports = { db };




