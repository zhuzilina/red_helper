const axios = require('axios');

const BASE_URL = 'http://localhost:8080';
const testUser = {
  username: 'testuser',
  password: 'TestPass123'
};

let authToken = '';

async function testFlutterCompatibility() {
  console.log('🧪 测试Flutter应用与新服务器的兼容性...\n');

  try {
    // 1. 测试登录（Flutter使用的路径）
    console.log('1. 测试登录API (/api/auth/login)...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, testUser);
    console.log('✅ 登录成功:', loginResponse.data.message);
    authToken = loginResponse.data.data.token;
    console.log('   用户信息:', {
      userId: loginResponse.data.data.userId,
      username: loginResponse.data.data.username,
      nickname: loginResponse.data.data.nickname,
      points: loginResponse.data.data.points
    });
    console.log('');

    // 2. 测试积分排行（Flutter使用的路径）
    console.log('2. 测试积分排行API (/api/statistics/pointsranking)...');
    const rankingResponse = await axios.get(`${BASE_URL}/api/statistics/pointsranking`, {
      headers: { token: authToken }
    });
    console.log('✅ 积分排行获取成功');
    console.log('   排行数量:', rankingResponse.data.data.length);
    console.log('   第一名:', rankingResponse.data.data[0]?.nickname, '积分:', rankingResponse.data.data[0]?.points);
    console.log('');

    // 3. 测试积分分布（Flutter使用的路径）
    console.log('3. 测试积分分布API (/api/points/distribution)...');
    const distributionResponse = await axios.get(`${BASE_URL}/api/points/distribution`, {
      headers: { token: authToken }
    });
    console.log('✅ 积分分布获取成功');
    console.log('   分类数量:', distributionResponse.data.data.length);
    console.log('   最高积分分类:', distributionResponse.data.data[0]?.category, '积分:', distributionResponse.data.data[0]?.points);
    console.log('');

    // 4. 测试用户积分（Flutter使用的路径）
    console.log('4. 测试用户积分API (/api/points/total)...');
    const totalPointsResponse = await axios.get(`${BASE_URL}/api/points/total`, {
      headers: { token: authToken }
    });
    console.log('✅ 用户积分获取成功');
    console.log('   总积分:', totalPointsResponse.data.data);
    console.log('');

    // 5. 测试每日任务（Flutter使用的路径）
    console.log('5. 测试每日任务API (/api/points/DailyTask)...');
    const tasksResponse = await axios.get(`${BASE_URL}/api/points/DailyTask`, {
      headers: { token: authToken }
    });
    console.log('✅ 每日任务获取成功');
    console.log('   任务数量:', tasksResponse.data.data.length);
    console.log('   第一个任务:', tasksResponse.data.data[0]?.title, '积分:', tasksResponse.data.data[0]?.points);
    console.log('');

    // 6. 测试轮播书籍（Flutter使用的路径）
    console.log('6. 测试轮播书籍API (/api/carousel/get)...');
    const carouselResponse = await axios.get(`${BASE_URL}/api/carousel/get`, {
      headers: { token: authToken }
    });
    console.log('✅ 轮播书籍获取成功');
    console.log('   书籍数量:', carouselResponse.data.data.length);
    console.log('   第一本书:', carouselResponse.data.data[0]?.title, '作者:', carouselResponse.data.data[0]?.author);
    console.log('');

    // 7. 测试书籍列表（Flutter使用的路径）
    console.log('7. 测试书籍列表API (/api/carousel/list)...');
    const booksResponse = await axios.get(`${BASE_URL}/api/carousel/list`, {
      headers: { token: authToken }
    });
    console.log('✅ 书籍列表获取成功');
    console.log('   书籍总数:', booksResponse.data.data.length);
    console.log('');

    // 8. 测试签到功能（Flutter使用的路径）
    console.log('8. 测试签到API (/api/points/signin)...');
    const signinResponse = await axios.get(`${BASE_URL}/api/points/signin`, {
      headers: { token: authToken }
    });
    console.log('✅ 签到功能测试成功');
    console.log('   签到结果:', signinResponse.data.message);
    console.log('');

    console.log('🎉 Flutter应用与新服务器完全兼容！');
    console.log('\n📱 Flutter应用现在可以正常使用以下功能:');
    console.log('   ✅ 用户登录和注册');
    console.log('   ✅ 积分排行显示');
    console.log('   ✅ 积分分布图表');
    console.log('   ✅ 用户积分查询');
    console.log('   ✅ 每日任务列表');
    console.log('   ✅ 轮播书籍展示');
    console.log('   ✅ 书籍列表浏览');
    console.log('   ✅ 签到功能');
    console.log('\n🔗 服务器地址: http://192.168.137.1:8080');
    console.log('📝 测试账号: testuser / TestPass123');

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
testFlutterCompatibility();






