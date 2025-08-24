const net = require('net');
const { spawn } = require('child_process');

// 尝试的端口列表
const PORTS = [8080, 8081, 8082, 8083, 8084, 3001, 3002, 3003, 3004, 3005];

// 检查端口是否可用
function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    
    server.listen(port, '127.0.0.1', () => {
      server.once('close', () => {
        resolve(true);
      });
      server.close();
    });
    
    server.on('error', () => {
      resolve(false);
    });
  });
}

// 查找可用端口
async function findAvailablePort() {
  for (const port of PORTS) {
    const available = await isPortAvailable(port);
    if (available) {
      return port;
    }
  }
  throw new Error('没有找到可用的端口');
}

// 启动服务器
async function startServer() {
  try {
    console.log('🔍 正在查找可用端口...');
    const port = await findAvailablePort();
    console.log(`✅ 找到可用端口: ${port}`);
    
    // 设置环境变量
    process.env.PORT = port;
    
    // 启动服务器
    const server = spawn('node', ['temp_auth_server.js'], {
      stdio: 'inherit',
      env: { ...process.env, PORT: port }
    });
    
    server.on('error', (error) => {
      console.error('❌ 启动服务器失败:', error.message);
    });
    
    server.on('close', (code) => {
      if (code !== 0) {
        console.log(`❌ 服务器进程退出，退出码: ${code}`);
      }
    });
    
  } catch (error) {
    console.error('❌ 启动失败:', error.message);
    console.log('💡 请尝试手动指定端口: PORT=3001 node temp_auth_server.js');
  }
}

// 运行启动脚本
startServer();
