const { db } = require('./connection');
const logger = require('../utils/logger');

// 创建数据库表
const createTables = () => {
  return new Promise((resolve, reject) => {
    // 用户表
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        nickname TEXT,
        email TEXT,
        avatar TEXT DEFAULT 'https://via.placeholder.com/50',
        points INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 好友排行榜表
    const createFriendRankingTable = `
      CREATE TABLE IF NOT EXISTS friend_ranking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        nickname TEXT NOT NULL,
        avatar TEXT DEFAULT 'https://via.placeholder.com/50',
        points INTEGER NOT NULL,
        rank INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 积分分布表
    const createPointsDistributionTable = `
      CREATE TABLE IF NOT EXISTS points_distribution (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        points INTEGER NOT NULL,
        percentage REAL NOT NULL,
        color TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 书籍表
    const createBooksTable = `
      CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        cover TEXT NOT NULL,
        description TEXT,
        category TEXT,
        is_featured INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 每日任务表
    const createDailyTasksTable = `
      CREATE TABLE IF NOT EXISTS daily_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        is_completed INTEGER DEFAULT 0,
        completed_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 商品表
    const createProductsTable = `
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        image TEXT NOT NULL,
        points_required INTEGER NOT NULL,
        stock INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // 用户签到记录表
    const createSignInRecordsTable = `
      CREATE TABLE IF NOT EXISTS sign_in_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sign_in_date DATE NOT NULL,
        points_earned INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, sign_in_date)
      )
    `;

    // 兑换记录表
    const createExchangeRecordsTable = `
      CREATE TABLE IF NOT EXISTS exchange_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        points_spent INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    `;

    const tables = [
      createUsersTable,
      createFriendRankingTable,
      createPointsDistributionTable,
      createBooksTable,
      createDailyTasksTable,
      createProductsTable,
      createSignInRecordsTable,
      createExchangeRecordsTable
    ];

    let completed = 0;
    const total = tables.length;

    tables.forEach((sql, index) => {
      db.run(sql, (err) => {
        if (err) {
          logger.error(`创建表 ${index + 1} 失败:`, err);
          reject(err);
          return;
        }
        
        completed++;
        logger.info(`表 ${index + 1}/${total} 创建成功`);
        
        if (completed === total) {
          logger.info('所有数据库表创建完成');
          resolve();
        }
      });
    });
  });
};

// 插入默认数据
const insertDefaultData = () => {
  return new Promise((resolve, reject) => {
    // 默认用户 - 使用正确的密码哈希
    const defaultUsers = [
      ['testuser', '$2a$10$FPMo0TxeYZAL2VJC5VbtKeSuLeNapl60uJ4GNtoJN8yW6ioStrICW', '测试用户']
    ];

    // 默认积分排行
    const defaultRanking = [
      ['张三', '张三', 'https://via.placeholder.com/50', 1250, 1],
      ['李四', '李四', 'https://via.placeholder.com/50', 980, 2],
      ['王五', '王五', 'https://via.placeholder.com/50', 756, 3],
      ['赵六', '赵六', 'https://via.placeholder.com/50', 650, 4],
      ['孙七', '孙七', 'https://via.placeholder.com/50', 520, 5]
    ];

    // 默认积分分布
    const defaultDistribution = [
      ['学习任务', 450, 36.0, '#FF6B6B'],
      ['运动健康', 320, 25.6, '#4ECDC4'],
      ['社交互动', 280, 22.4, '#45B7D1'],
      ['其他活动', 200, 16.0, '#96CEB4']
    ];

    // 默认书籍
    const defaultBooks = [
      ['红色记忆', '作者A', 'https://via.placeholder.com/200x300', '革命历史小说', '历史', 1],
      ['长征路上', '作者B', 'https://via.placeholder.com/200x300', '长征纪实文学', '纪实', 1],
      ['红色文化', '作者C', 'https://via.placeholder.com/200x300', '文化研究著作', '文化', 0],
      ['革命故事', '作者D', 'https://via.placeholder.com/200x300', '革命故事集', '故事', 0],
      ['红色教育', '作者E', 'https://via.placeholder.com/200x300', '教育类图书', '教育', 0]
    ];

    // 默认每日任务
    const defaultTasks = [
      ['每日签到', '完成每日签到获得积分', 10],
      ['阅读文章', '阅读一篇红色文化文章', 20],
      ['运动打卡', '完成今日运动目标', 15],
      ['分享心得', '分享学习心得', 25],
      ['学习打卡', '完成今日学习任务', 30]
    ];

    // 默认商品
    const defaultProducts = [
      ['红色文化T恤', '印有革命历史图案的T恤', 'https://via.placeholder.com/200x200', 500, 10],
      ['纪念徽章', '长征纪念徽章', 'https://via.placeholder.com/200x200', 300, 20],
      ['红色书籍', '精选红色文化书籍', 'https://via.placeholder.com/200x200', 800, 5],
      ['纪念水杯', '印有革命历史图案的水杯', 'https://via.placeholder.com/200x200', 400, 15]
    ];

    // 插入用户数据
    db.run("DELETE FROM users", (err) => {
      if (err) {
        logger.error('清空用户数据失败:', err);
        reject(err);
        return;
      }
      
      const stmt = db.prepare("INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)");
      defaultUsers.forEach(row => stmt.run(row));
      stmt.finalize();
      logger.info('默认用户数据插入完成');
    });

    // 插入积分排行数据
    db.run("DELETE FROM friend_ranking", (err) => {
      if (err) {
        logger.error('清空积分排行数据失败:', err);
        reject(err);
        return;
      }
      
      const stmt = db.prepare("INSERT INTO friend_ranking (username, nickname, avatar, points, rank) VALUES (?, ?, ?, ?, ?)");
      defaultRanking.forEach(row => stmt.run(row));
      stmt.finalize();
      logger.info('默认积分排行数据插入完成');
    });

    // 插入积分分布数据
    db.run("DELETE FROM points_distribution", (err) => {
      if (err) {
        logger.error('清空积分分布数据失败:', err);
        reject(err);
        return;
      }
      
      const stmt = db.prepare("INSERT INTO points_distribution (category, points, percentage, color) VALUES (?, ?, ?, ?)");
      defaultDistribution.forEach(row => stmt.run(row));
      stmt.finalize();
      logger.info('默认积分分布数据插入完成');
    });

    // 插入书籍数据
    db.run("DELETE FROM books", (err) => {
      if (err) {
        logger.error('清空书籍数据失败:', err);
        reject(err);
        return;
      }
      
      const stmt = db.prepare("INSERT INTO books (title, author, cover, description, category, is_featured) VALUES (?, ?, ?, ?, ?, ?)");
      defaultBooks.forEach(row => stmt.run(row));
      stmt.finalize();
      logger.info('默认书籍数据插入完成');
    });

    // 插入每日任务数据
    db.run("DELETE FROM daily_tasks", (err) => {
      if (err) {
        logger.error('清空每日任务数据失败:', err);
        reject(err);
        return;
      }
      
      const stmt = db.prepare("INSERT INTO daily_tasks (title, description, points) VALUES (?, ?, ?)");
      defaultTasks.forEach(row => stmt.run(row));
      stmt.finalize();
      logger.info('默认每日任务数据插入完成');
    });

    // 插入商品数据
    db.run("DELETE FROM products", (err) => {
      if (err) {
        logger.error('清空商品数据失败:', err);
        reject(err);
        return;
      }
      
      const stmt = db.prepare("INSERT INTO products (name, description, image, points_required, stock) VALUES (?, ?, ?, ?, ?)");
      defaultProducts.forEach(row => stmt.run(row));
      stmt.finalize();
      logger.info('默认商品数据插入完成');
    });

    // 设置测试用户积分
    db.run("UPDATE users SET points = 1250 WHERE username = 'testuser'", (err) => {
      if (err) {
        logger.error('更新测试用户积分失败:', err);
      } else {
        logger.info('测试用户积分设置完成');
      }
    });

    resolve();
  });
};

// 初始化数据库
const initDatabase = async () => {
  try {
    logger.info('开始初始化数据库...');
    await createTables();
    await insertDefaultData();
    logger.info('数据库初始化完成');
  } catch (error) {
    logger.error('数据库初始化失败:', error);
    throw error;
  }
};

module.exports = {
  initDatabase,
  createTables,
  insertDefaultData
};
