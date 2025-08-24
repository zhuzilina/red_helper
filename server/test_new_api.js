const axios = require('axios');

const BASE_URL = 'http://localhost:8080';

// 测试数据
const testUser = {
  username: 'testuser',
  password: 'TestPass123'
};

let authToken = '';

async function testNewAPI() {
  console.log('🧪 测试新的标准Express.js服务器API...\n');

  try {
    // 1. 测试健康检查
    console.log('1. 测试健康检查...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ 健康检查通过:', healthResponse.data.message);
    console.log('   环境:', healthResponse.data.environment);
    console.log('   时间戳:', healthResponse.data.timestamp);
    console.log('');

    // 2. 测试用户登录
    console.log('2. 测试用户登录...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, testUser);
    console.log('✅ 登录成功:', loginResponse.data.message);
    authToken = loginResponse.data.data.token;
    console.log('   获取到令牌:', authToken.substring(0, 20) + '...');
    console.log('   用户信息:', {
      userId: loginResponse.data.data.userId,
      username: loginResponse.data.data.username,
      nickname: loginResponse.data.data.nickname,
      points: loginResponse.data.data.points
    });
    console.log('');

    // 3. 测试获取用户信息
    console.log('3. 测试获取用户信息...');
    const profileResponse = await axios.get(`${BASE_URL}/api/user/profile`, {
      headers: { token: authToken }
    });
    console.log('✅ 用户信息获取成功');
    console.log('   用户ID:', profileResponse.data.data.id);
    console.log('   用户名:', profileResponse.data.data.username);
    console.log('   昵称:', profileResponse.data.data.nickname);
    console.log('   积分:', profileResponse.data.data.points);
    console.log('');

    // 4. 测试获取积分排行
    console.log('4. 测试获取积分排行...');
    const rankingResponse = await axios.get(`${BASE_URL}/api/statistics/pointsranking`, {
      headers: { token: authToken }
    });
    console.log('✅ 积分排行获取成功');
    console.log('   排行数量:', rankingResponse.data.data.length);
    console.log('   第一名:', rankingResponse.data.data[0]?.nickname, '积分:', rankingResponse.data.data[0]?.points);
    console.log('');

    // 5. 测试获取积分分布
    console.log('5. 测试获取积分分布...');
    const distributionResponse = await axios.get(`${BASE_URL}/api/points/distribution`, {
      headers: { token: authToken }
    });
    console.log('✅ 积分分布获取成功');
    console.log('   分类数量:', distributionResponse.data.data.length);
    console.log('   最高积分分类:', distributionResponse.data.data[0]?.category, '积分:', distributionResponse.data.data[0]?.points);
    console.log('');

    // 6. 测试获取用户总积分
    console.log('6. 测试获取用户总积分...');
    const totalPointsResponse = await axios.get(`${BASE_URL}/api/points/total`, {
      headers: { token: authToken }
    });
    console.log('✅ 用户总积分获取成功');
    console.log('   总积分:', totalPointsResponse.data.data);
    console.log('');

    // 7. 测试获取每日任务
    console.log('7. 测试获取每日任务...');
    const tasksResponse = await axios.get(`${BASE_URL}/api/points/DailyTask`, {
      headers: { token: authToken }
    });
    console.log('✅ 每日任务获取成功');
    console.log('   任务数量:', tasksResponse.data.data.length);
    console.log('   第一个任务:', tasksResponse.data.data[0]?.title, '积分:', tasksResponse.data.data[0]?.points);
    console.log('');

    // 8. 测试获取轮播书籍
    console.log('8. 测试获取轮播书籍...');
    const carouselResponse = await axios.get(`${BASE_URL}/api/carousel/get`, {
      headers: { token: authToken }
    });
    console.log('✅ 轮播书籍获取成功');
    console.log('   书籍数量:', carouselResponse.data.data.length);
    console.log('   第一本书:', carouselResponse.data.data[0]?.title, '作者:', carouselResponse.data.data[0]?.author);
    console.log('');

    // 9. 测试获取书籍列表
    console.log('9. 测试获取书籍列表...');
    const booksResponse = await axios.get(`${BASE_URL}/api/carousel/list`, {
      headers: { token: authToken }
    });
    console.log('✅ 书籍列表获取成功');
    console.log('   书籍总数:', booksResponse.data.data.length);
    console.log('');

    // 10. 测试令牌验证
    console.log('10. 测试令牌验证...');
    const verifyResponse = await axios.get(`${BASE_URL}/api/auth/verify`, {
      headers: { token: authToken }
    });
    console.log('✅ 令牌验证成功:', verifyResponse.data.message);
    console.log('');

    console.log('🎉 所有新API测试通过！标准Express.js服务器运行正常。');
    console.log('\n📝 测试账号信息:');
    console.log(`   用户名: ${testUser.username}`);
    console.log(`   密码: ${testUser.password}`);
    console.log('\n🔗 服务器地址: http://localhost:8080');
    console.log('\n📊 新API特点:');
    console.log('   - 标准RESTful API设计');
    console.log('   - 完整的错误处理机制');
    console.log('   - 请求限制和安全性');
    console.log('   - 结构化日志系统');
    console.log('   - 环境变量配置');
    console.log('   - 数据库自动初始化');

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (error.response) {
      console.error('   状态码:', error.response.status);
      console.error('   错误信息:', error.response.data);
    }
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 请确保服务器正在运行: npm start');
    }
  }
}

// 运行测试
testNewAPI();




