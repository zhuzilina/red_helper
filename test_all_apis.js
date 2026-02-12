const axios = require('axios');

const BASE_URL = 'http://localhost:8080';

// 测试数据
const testUser = {
  username: 'testuser',
  password: 'TestPass123'
};

let authToken = '';

async function testAllAPIs() {
  console.log('🧪 开始全面测试临时认证服务器...\n');

  try {
    // 1. 测试健康检查
    console.log('1. 测试健康检查...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ 健康检查通过:', healthResponse.data.message);
    console.log('');

    // 2. 测试用户登录
    console.log('2. 测试用户登录...');
    const loginResponse = await axios.post(`${BASE_URL}/user/login`, testUser);
    console.log('✅ 登录成功:', loginResponse.data.message);
    authToken = loginResponse.data.data.token;
    console.log('   获取到令牌:', authToken.substring(0, 20) + '...');
    console.log('');

    // 3. 测试获取积分排行
    console.log('3. 测试获取积分排行...');
    const rankingResponse = await axios.get(`${BASE_URL}/statistics/pointsranking`, {
      headers: { token: authToken }
    });
    console.log('✅ 积分排行获取成功');
    console.log('   排行数量:', rankingResponse.data.data.length);
    console.log('   第一名:', rankingResponse.data.data[0]?.nickname);
    console.log('');

    // 4. 测试获取积分分布
    console.log('4. 测试获取积分分布...');
    const distributionResponse = await axios.get(`${BASE_URL}/points/distribution`, {
      headers: { token: authToken }
    });
    console.log('✅ 积分分布获取成功');
    console.log('   分类数量:', distributionResponse.data.data.length);
    console.log('   最高积分分类:', distributionResponse.data.data[0]?.category);
    console.log('');

    // 5. 测试获取用户总积分
    console.log('5. 测试获取用户总积分...');
    const totalPointsResponse = await axios.get(`${BASE_URL}/points/total`, {
      headers: { token: authToken }
    });
    console.log('✅ 用户总积分获取成功');
    console.log('   总积分:', totalPointsResponse.data.data);
    console.log('');

    // 6. 测试获取轮播书籍
    console.log('6. 测试获取轮播书籍...');
    const carouselResponse = await axios.get(`${BASE_URL}/carouse/get`, {
      headers: { token: authToken }
    });
    console.log('✅ 轮播书籍获取成功');
    console.log('   书籍数量:', carouselResponse.data.data.length);
    console.log('   第一本书:', carouselResponse.data.data[0]?.title);
    console.log('');

    // 7. 测试获取书籍列表
    console.log('7. 测试获取书籍列表...');
    const booksResponse = await axios.get(`${BASE_URL}/carouse/list`, {
      headers: { token: authToken }
    });
    console.log('✅ 书籍列表获取成功');
    console.log('   书籍总数:', booksResponse.data.data.length);
    console.log('');

    // 8. 测试获取每日任务
    console.log('8. 测试获取每日任务...');
    const tasksResponse = await axios.get(`${BASE_URL}/points/DailyTask`, {
      headers: { token: authToken }
    });
    console.log('✅ 每日任务获取成功');
    console.log('   任务数量:', tasksResponse.data.data.length);
    console.log('   第一个任务:', tasksResponse.data.data[0]?.title);
    console.log('');

    // 9. 测试签到功能
    console.log('9. 测试签到功能...');
    const signinResponse = await axios.get(`${BASE_URL}/points/signin`, {
      headers: { token: authToken }
    });
    console.log('✅ 签到成功:', signinResponse.data.message);
    console.log('   获得积分:', signinResponse.data.data.points);
    console.log('');

    // 10. 测试兑换商品
    console.log('10. 测试兑换商品...');
    const exchangeResponse = await axios.post(`${BASE_URL}/exchange`, {
      productId: 1
    }, {
      headers: { token: authToken }
    });
    console.log('✅ 商品兑换成功:', exchangeResponse.data.message);
    console.log('   剩余积分:', exchangeResponse.data.data.newPoints);
    console.log('');

    // 11. 测试获取用户信息
    console.log('11. 测试获取用户信息...');
    const profileResponse = await axios.get(`${BASE_URL}/user/profile`, {
      headers: { token: authToken }
    });
    console.log('✅ 用户信息获取成功');
    console.log('   用户名:', profileResponse.data.data.username);
    console.log('   昵称:', profileResponse.data.data.nickname);
    console.log('');

    // 12. 测试令牌验证
    console.log('12. 测试令牌验证...');
    const verifyResponse = await axios.get(`${BASE_URL}/user/verify`, {
      headers: { token: authToken }
    });
    console.log('✅ 令牌验证成功:', verifyResponse.data.message);
    console.log('');

    console.log('🎉 所有API测试通过！服务器运行正常。');
    console.log('\n📝 测试账号信息:');
    console.log(`   用户名: ${testUser.username}`);
    console.log(`   密码: ${testUser.password}`);
    console.log('\n🔗 服务器地址: http://localhost:8080');
    console.log('\n📊 数据库已包含以下默认数据:');
    console.log('   - 5个积分排行用户');
    console.log('   - 4个积分分布分类');
    console.log('   - 5本红色文化书籍');
    console.log('   - 5个每日任务');
    console.log('   - 4个兑换商品');

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
testAllAPIs();
