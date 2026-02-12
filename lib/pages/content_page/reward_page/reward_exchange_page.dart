import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/points_state.dart';
import 'widget/exchange/user_profile_card.dart';
import 'widget/exchange/action_buttons.dart';
import 'widget/exchange/category_menu.dart';
import 'widget/exchange/product_item.dart';
import 'widget/exchange/category_header_delegate.dart';
import 'package:red_helper/route/routes.dart';
import 'package:red_helper/repository/models/model.dart';

class RewardExchangePage extends StatefulWidget {
  const RewardExchangePage({super.key});

  @override
  _RewardExchangePageState createState() => _RewardExchangePageState();
}

class _RewardExchangePageState extends State<RewardExchangePage> {
  final List<String> categories = ['最新', '最热', '生活用品', '食品', '数码产品'];
  int selectedCategory = 0;
  late List<Product> products;

  @override
  void initState() {
    super.initState();
    products = _generateDemoProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pointsState = Provider.of<PointsState>(context, listen: false);
      pointsState.fetchPoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pointsState = Provider.of<PointsState>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xfffcbfa6), Color(0xffffe7cd)],
                  center: Alignment.topCenter,
                  radius: 1.2,
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 68,
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                title: const Text(
                  '积分兑换',
                  style: TextStyle(
                    fontFamily: 'blockLetter',
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.2,
                  ),
                  child: UserProfileCard(
                    avatarUrl:
                        'http://121.199.16.109:8080/2025/04/16/d32a6c85-7d19-47d7-82dd-b6b2899de6c2.jpg',
                    username: '旅行达人小美',
                    points: pointsState.currentPoints,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverToBoxAdapter(
                  child: ActionButtons(
                    onEarnPoints:
                        () => Navigator.pushNamed(context, RoutePath.task),
                    onViewDetails: () {},
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: CategoryHeaderDelegate(
                  child: CategoryMenu(
                    categories: categories,
                    selectedIndex: selectedCategory,
                    onCategorySelected: (index) {
                      selectedCategory = index;
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final products = _generateDemoProducts();
                    return ProductItem(
                      productName: products[index].name,
                      points: products[index].points,
                      imageUrl: products[index].imageUrl,
                    );
                  }, childCount: _generateDemoProducts().length),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Product> _generateDemoProducts() {
  return [
    Product(
      '马克杯',
      800,
      'https://tse1-mm.cn.bing.net/th/id/OIP-C.XCDKAyHauOG6yBZWxmc3PAHaGR?w=249&h=211&c=7&r=0&o=5&dpr=1.2&pid=1.7',
    ),
    Product(
      '不锈钢真空保温杯',
      900,
      'https://tse4-mm.cn.bing.net/th/id/OIP-C.XomorCMMdFphu4cWlmXBfwHaFu?w=274&h=211&c=7&r=0&o=5&dpr=1.2&pid=1.7',
    ),
    Product(
      '书籍：红星照耀中国',
      1200,
      'https://bkimg.cdn.bcebos.com/pic/b999a9014c086e061d95d6c928506cf40ad163d95da2?x-bce-process=image/format,f_auto/quality,Q_70/resize,m_lfit,limit_1,w_536',
    ),
    Product(
      '运动旅行背包',
      1500,
      'https://tse3-mm.cn.bing.net/th/id/OIP-C.utDuNSNORxlENaso4bZnMgHaHa?w=199&h=199&c=7&r=0&o=5&dpr=1.2&pid=1.7',
    ),
    Product(
      '新疆棉花被子',
      2000,
      'https://tse4-mm.cn.bing.net/th/id/OIP-C.n5FiDl1uf8dNLtuaOoegfAHaHa?w=185&h=186&c=7&r=0&o=5&dpr=1.2&pid=1.7',
    ),
  ];
}
