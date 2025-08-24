const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080; // 使用环境变量或默认端口8080

// 中间件配置
app.use(cors());
app.use(bodyParser.json());

// 数据库配置
const dbPath = path.join(__dirname, 'temp_auth.db');
const db = new sqlite3.Database(dbPath);

// JWT密钥
const JWT_SECRET = 'your-secret-key-change-in-production';

// 初始化数据库
function initDatabase() {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // 用户表
      db.run(`
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          nickname TEXT,
          phone TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // 积分排行表
      db.run(`
        CREATE TABLE IF NOT EXISTS friend_ranking (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          nickname TEXT,
          avatar TEXT,
          points INTEGER DEFAULT 0,
          rank INTEGER DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // 积分分布表
      db.run(`
        CREATE TABLE IF NOT EXISTS points_distribution (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          points INTEGER DEFAULT 0,
          percentage REAL DEFAULT 0,
          color TEXT DEFAULT '#FF6B6B',
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // 书籍轮播表
      db.run(`
        CREATE TABLE IF NOT EXISTS books (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT,
          cover TEXT,
          description TEXT,
          category TEXT,
          is_featured BOOLEAN DEFAULT 0,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // 每日任务表
      db.run(`
        CREATE TABLE IF NOT EXISTS daily_tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          points INTEGER DEFAULT 0,
          is_completed BOOLEAN DEFAULT 0,
          completed_at DATETIME,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // 商品兑换表
      db.run(`
        CREATE TABLE IF NOT EXISTS products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          image TEXT,
          points_required INTEGER DEFAULT 0,
          stock INTEGER DEFAULT 0,
          is_available BOOLEAN DEFAULT 1,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // 插入默认数据
      insertDefaultData().then(() => {
        console.log('✅ 数据库初始化完成');
        resolve();
      }).catch(reject);
    });
  });
}

// 插入默认数据
async function insertDefaultData() {
  return new Promise((resolve, reject) => {
    // 检查是否已有默认用户
    db.get("SELECT COUNT(*) as count FROM users WHERE username = 'testuser'", (err, row) => {
      if (err) {
        reject(err);
        return;
      }

      if (row.count === 0) {
        // 插入默认用户
        const hashedPassword = bcrypt.hashSync('TestPass123', 10);
        db.run(
          "INSERT INTO users (username, password, nickname) VALUES (?, ?, ?)",
          ['testuser', hashedPassword, '测试用户'],
          function(err) {
            if (err) {
              console.error('插入默认用户失败:', err);
            } else {
              console.log('🧩 已预置测试账号: username=testuser, password=TestPass123');
            }
          }
        );
      }

      // 插入默认积分排行数据
      const defaultRanking = [
        ['张三', '张三', 'https://via.placeholder.com/50', 1250, 1],
        ['李四', '李四', 'https://via.placeholder.com/50', 980, 2],
        ['王五', '王五', 'https://via.placeholder.com/50', 756, 3],
        ['赵六', '赵六', 'https://via.placeholder.com/50', 650, 4],
        ['孙七', '孙七', 'https://via.placeholder.com/50', 520, 5],
      ];

      db.run("DELETE FROM friend_ranking", (err) => {
        if (err) console.error('清空积分排行失败:', err);
        
        const stmt = db.prepare("INSERT INTO friend_ranking (username, nickname, avatar, points, rank) VALUES (?, ?, ?, ?, ?)");
        defaultRanking.forEach(row => stmt.run(row));
        stmt.finalize();
      });

      // 插入默认积分分布数据
      const defaultDistribution = [
        ['学习任务', 450, 36.0, '#FF6B6B'],
        ['运动健康', 320, 25.6, '#4ECDC4'],
        ['社交互动', 280, 22.4, '#45B7D1'],
        ['其他活动', 200, 16.0, '#96CEB4'],
      ];

      db.run("DELETE FROM points_distribution", (err) => {
        if (err) console.error('清空积分分布失败:', err);
        
        const stmt = db.prepare("INSERT INTO points_distribution (category, points, percentage, color) VALUES (?, ?, ?, ?)");
        defaultDistribution.forEach(row => stmt.run(row));
        stmt.finalize();
      });

      // 插入默认书籍数据
      const defaultBooks = [
        ['红色记忆', '作者A', 'https://via.placeholder.com/200x300', '革命历史小说', '历史', 1],
        ['长征路上', '作者B', 'https://via.placeholder.com/200x300', '长征纪实文学', '纪实', 1],
        ['红色文化', '作者C', 'https://via.placeholder.com/200x300', '文化研究著作', '文化', 0],
        ['革命故事', '作者D', 'https://via.placeholder.com/200x300', '革命故事集', '故事', 0],
        ['红色教育', '作者E', 'https://via.placeholder.com/200x300', '教育类图书', '教育', 0],
      ];

      db.run("DELETE FROM books", (err) => {
        if (err) console.error('清空书籍数据失败:', err);
        
        const stmt = db.prepare("INSERT INTO books (title, author, cover, description, category, is_featured) VALUES (?, ?, ?, ?, ?, ?)");
        defaultBooks.forEach(row => stmt.run(row));
        stmt.finalize();
      });

      // 插入默认每日任务
      const defaultTasks = [
        ['每日签到', '完成每日签到获得积分', 10],
        ['阅读文章', '阅读一篇红色文化文章', 20],
        ['运动打卡', '完成今日运动目标', 15],
        ['分享心得', '分享学习心得', 25],
        ['知识问答', '参与红色知识问答', 30],
      ];

      db.run("DELETE FROM daily_tasks", (err) => {
        if (err) console.error('清空每日任务失败:', err);
        
        const stmt = db.prepare("INSERT INTO daily_tasks (title, description, points) VALUES (?, ?, ?)");
        defaultTasks.forEach(row => stmt.run(row));
        stmt.finalize();
      });

      // 插入默认商品
      const defaultProducts = [
        ['红色文化T恤', '印有革命历史图案的T恤', 'https://via.placeholder.com/200x200', 500, 10],
        ['纪念徽章', '长征纪念徽章', 'https://via.placeholder.com/200x200', 300, 20],
        ['红色书籍', '精选红色文化书籍', 'https://via.placeholder.com/200x200', 800, 5],
        ['纪念水杯', '印有革命历史图案的水杯', 'https://via.placeholder.com/200x200', 400, 15],
      ];

      db.run("DELETE FROM products", (err) => {
        if (err) console.error('清空商品数据失败:', err);
        
        const stmt = db.prepare("INSERT INTO products (name, description, image, points_required, stock) VALUES (?, ?, ?, ?, ?)");
        defaultProducts.forEach(row => stmt.run(row));
        stmt.finalize();
      });

      resolve();
    });
  });
}

// 生成JWT令牌
function generateToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' });
}

// 验证JWT令牌
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

// 用户注册接口
app.post('/user/register', async (req, res) => {
  try {
    const { username, password } = req.body;

    // 验证输入
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: '用户名和密码不能为空'
      });
    }

    // 检查用户名是否已存在
    db.get("SELECT id FROM users WHERE username = ?", [username], (err, row) => {
      if (err) {
        console.error('查询用户失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (row) {
        return res.status(400).json({
          success: false,
          message: '用户名已存在'
        });
      }

      // 密码强度验证
      if (password.length < 8) {
        return res.status(400).json({
          success: false,
          message: '密码至少需要8个字符'
        });
      }

      // 加密密码并创建用户
      const hashedPassword = bcrypt.hashSync(password, 10);
      db.run(
        "INSERT INTO users (username, password) VALUES (?, ?)",
        [username, hashedPassword],
        function(err) {
          if (err) {
            console.error('创建用户失败:', err);
            return res.status(500).json({
              success: false,
              message: '服务器内部错误'
            });
          }

          res.status(200).json({
            success: true,
            message: '注册成功',
            data: {
              userId: this.lastID,
              username: username
            }
          });
        }
      );
    });

  } catch (error) {
    console.error('注册错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 用户登录接口
app.post('/user/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // 验证输入
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: '用户名和密码不能为空'
      });
    }

    // 查找用户
    db.get("SELECT * FROM users WHERE username = ?", [username], (err, user) => {
      if (err) {
        console.error('查询用户失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (!user) {
        return res.status(401).json({
          success: false,
          message: '用户名或密码错误'
        });
      }

      // 验证密码
      const isPasswordValid = bcrypt.compareSync(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: '用户名或密码错误'
        });
      }

      // 生成JWT令牌
      const token = generateToken(user.id);

      res.status(200).json({
        success: true,
        message: '登录成功',
        data: {
          token,
          userId: user.id,
          username: user.username
        }
      });
    });

  } catch (error) {
    console.error('登录错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 验证令牌接口
app.get('/user/verify', (req, res) => {
  try {
    const token = req.headers.token || req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }

    const decoded = verifyToken(token);
    if (!decoded) {
      return res.status(401).json({
        success: false,
        message: '无效的认证令牌'
      });
    }

    db.get("SELECT id, username FROM users WHERE id = ?", [decoded.userId], (err, user) => {
      if (err) {
        console.error('查询用户失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (!user) {
        return res.status(401).json({
          success: false,
          message: '用户不存在'
        });
      }

      res.status(200).json({
        success: true,
        message: '令牌有效',
        data: {
          userId: user.id,
          username: user.username
        }
      });
    });

  } catch (error) {
    console.error('令牌验证错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 用户登出接口
app.post('/user/logout', (req, res) => {
  res.status(200).json({
    success: true,
    message: '登出成功'
  });
});

// 获取用户信息接口
app.get('/user/profile', (req, res) => {
  try {
    const token = req.headers.token || req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: '未提供认证令牌'
      });
    }

    const decoded = verifyToken(token);
    if (!decoded) {
      return res.status(401).json({
        success: false,
        message: '无效的认证令牌'
      });
    }

    db.get("SELECT id, username, nickname, created_at FROM users WHERE id = ?", [decoded.userId], (err, user) => {
      if (err) {
        console.error('查询用户失败:', err);
        return res.status(500).json({
          success: false,
          message: '服务器内部错误'
        });
      }

      if (!user) {
        return res.status(404).json({
          success: false,
          message: '用户不存在'
        });
      }

      res.status(200).json({
        success: true,
        data: {
          userId: user.id,
          username: user.username,
          nickname: user.nickname,
          createdAt: user.created_at
        }
      });
    });

  } catch (error) {
    console.error('获取用户信息错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 获取好友排行榜
app.get('/statistics/pointsranking', (req, res) => {
  db.all("SELECT * FROM friend_ranking ORDER BY rank ASC", (err, rows) => {
    if (err) {
      console.error('查询积分排行失败:', err);
      return res.status(500).json({
        success: false,
        message: '获取积分排行失败'
      });
    }

    res.status(200).json({
      success: true,
      data: rows
    });
  });
});

// 获取积分分布
app.get('/points/distribution', (req, res) => {
  db.all("SELECT * FROM points_distribution ORDER BY points DESC", (err, rows) => {
    if (err) {
      console.error('查询积分分布失败:', err);
      return res.status(500).json({
        success: false,
        message: '获取积分分布失败'
      });
    }

    res.status(200).json({
      success: true,
      data: rows
    });
  });
});

// 获取用户总积分
app.get('/points/total', (req, res) => {
  // 这里简单返回一个固定值，实际应该根据用户ID查询
  res.status(200).json({
    success: true,
    data: 1250
  });
});

// 获取轮播书籍
app.get('/carouse/get', (req, res) => {
  db.all("SELECT * FROM books WHERE is_featured = 1 ORDER BY created_at DESC LIMIT 5", (err, rows) => {
    if (err) {
      console.error('查询轮播书籍失败:', err);
      return res.status(500).json({
        success: false,
        message: '获取轮播书籍失败'
      });
    }

    res.status(200).json({
      success: true,
      data: rows
    });
  });
});

// 获取书籍列表
app.get('/carouse/list', (req, res) => {
  db.all("SELECT * FROM books ORDER BY created_at DESC", (err, rows) => {
    if (err) {
      console.error('查询书籍列表失败:', err);
      return res.status(500).json({
        success: false,
        message: '获取书籍列表失败'
      });
    }

    res.status(200).json({
      success: true,
      data: rows
    });
  });
});

// 获取每日任务
app.get('/points/DailyTask', (req, res) => {
  db.all("SELECT * FROM daily_tasks ORDER BY id ASC", (err, rows) => {
    if (err) {
      console.error('查询每日任务失败:', err);
      return res.status(500).json({
        success: false,
        message: '获取每日任务失败'
      });
    }

    res.status(200).json({
      success: true,
      data: rows
    });
  });
});

// 签到接口
app.get('/points/signin', (req, res) => {
  // 这里应该检查用户是否已经签到，避免重复签到
  res.status(200).json({
    success: true,
    message: '签到成功',
    data: {
      points: 10
    }
  });
});

// 兑换商品接口
app.post('/exchange', (req, res) => {
  const { productId } = req.body;
  
  if (!productId) {
    return res.status(400).json({
      success: false,
      message: '商品ID不能为空'
    });
  }

  // 这里应该检查用户积分是否足够，更新库存等
  res.status(200).json({
    success: true,
    message: '兑换成功',
    data: {
      newPoints: 750 // 假设用户剩余积分
    }
  });
});

// 健康检查接口
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: '服务器运行正常',
    timestamp: new Date().toISOString()
  });
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({
    success: false,
    message: '服务器内部错误'
  });
});

// 404处理
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: '接口不存在'
  });
});

// 启动服务器
async function startServer() {
  try {
    await initDatabase();
    
    app.listen(PORT, '0.0.0.0', (err) => {
      if (err) {
        console.error('❌ 服务器启动失败:', err.message);
        if (err.code === 'EACCES') {
          console.log('💡 权限不足，请尝试使用管理员权限运行或更换端口');
        } else if (err.code === 'EADDRINUSE') {
          console.log('💡 端口被占用，请尝试其他端口或关闭占用该端口的程序');
        }
        process.exit(1);
      }
      
      console.log(`✅ 临时认证服务器运行在 http://localhost:${PORT}`);
      console.log('📋 可用的接口:');
      console.log('  POST /user/register - 用户注册');
      console.log('  POST /user/login - 用户登录');
      console.log('  GET  /user/verify - 验证令牌');
      console.log('  POST /user/logout - 用户登出');
      console.log('  GET  /user/profile - 获取用户信息');
      console.log('  GET  /statistics/pointsranking - 获取积分排行');
      console.log('  GET  /points/distribution - 获取积分分布');
      console.log('  GET  /points/total - 获取用户总积分');
      console.log('  GET  /carouse/get - 获取轮播书籍');
      console.log('  GET  /carouse/list - 获取书籍列表');
      console.log('  GET  /points/DailyTask - 获取每日任务');
      console.log('  GET  /points/signin - 签到');
      console.log('  POST /exchange - 兑换商品');
      console.log('  GET  /health - 健康检查');
      console.log('\n🔧 如果需要在真机上测试，请将localhost改为本机IP地址');
    });
  } catch (error) {
    console.error('❌ 数据库初始化失败:', error);
    process.exit(1);
  }
}

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n🛑 正在关闭服务器...');
  db.close((err) => {
    if (err) {
      console.error('关闭数据库失败:', err);
    } else {
      console.log('✅ 数据库连接已关闭');
    }
    process.exit(0);
  });
});

startServer();

module.exports = app;
