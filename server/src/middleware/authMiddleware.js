const jwt = require('jsonwebtoken');
const { db } = require('../database/connection');
const logger = require('../utils/logger');

// 验证JWT令牌
const authMiddleware = (req, res, next) => {
  try {
    const token = req.header('token') || req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: '访问被拒绝，没有提供令牌'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // 验证用户是否存在
    db.get("SELECT id, username, nickname FROM users WHERE id = ?", [decoded.userId], (err, user) => {
      if (err) {
        logger.error('数据库查询错误:', err);
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

      req.user = user;
      next();
    });

  } catch (error) {
    logger.error('令牌验证失败:', error);
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: '令牌已过期'
      });
    }

    return res.status(401).json({
      success: false,
      message: '无效的令牌'
    });
  }
};

module.exports = {
  authMiddleware
};




