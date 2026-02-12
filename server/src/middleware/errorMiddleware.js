const logger = require('../utils/logger');

// 404错误处理
const notFound = (req, res, next) => {
  const error = new Error(`未找到路径: ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

// 全局错误处理
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // 记录错误日志
  logger.error('错误详情:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  // Mongoose错误处理
  if (err.name === 'CastError') {
    const message = '资源不存在';
    error = { message, statusCode: 404 };
  }

  // Mongoose重复键错误
  if (err.code === 11000) {
    const message = '数据已存在';
    error = { message, statusCode: 400 };
  }

  // Mongoose验证错误
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message).join(', ');
    error = { message, statusCode: 400 };
  }

  // JWT错误
  if (err.name === 'JsonWebTokenError') {
    const message = '无效的令牌';
    error = { message, statusCode: 401 };
  }

  // JWT过期错误
  if (err.name === 'TokenExpiredError') {
    const message = '令牌已过期';
    error = { message, statusCode: 401 };
  }

  // SQLite错误
  if (err.code === 'SQLITE_CONSTRAINT') {
    const message = '数据约束错误';
    error = { message, statusCode: 400 };
  }

  res.status(error.statusCode || 500).json({
    success: false,
    message: error.message || '服务器内部错误',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = {
  notFound,
  errorHandler
};




