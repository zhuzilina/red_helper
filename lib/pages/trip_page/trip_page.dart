import 'package:flutter/material.dart';

import 'package:red_helper/pages/content_page/web_view/web_view.dart';
import 'package:red_helper/pages/learn_page/learn_page.dart';
// 引入自定义组件
import 'widget/team_card.dart';
import 'widget/strategy_card.dart';
import 'widget/section_title.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key});

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  // 模拟数据
  final List<Map<String, dynamic>> attractions = [
    {
      'image':
          'http://pic.people.com.cn/mediafile/pic/BIG/20230519/5/12397810148944316541.jpg',
      'title': '中共一大会址',
      'desc': '红色的发源地',
    },
    {
      'image':
          'https://www.zunyihy.cn/n342/20220411/880/material/2f7caa1a-4c05-43c3-8482-461108fd9a40.jpg',
      'title': '遵义会议会址',
      'desc': '生死攸关的伟大转折',
    },
  ];

  final List<Map<String, dynamic>> teams = [
    {
      'avatar': 'https://picsum.photos/50?random=1',
      'name': '赵一曼故居参观',
      'date': '8月20日',
      'members': 3,
    },
    {
      'avatar': 'https://picsum.photos/50?random=2',
      'name': '江姐故居参观',
      'date': '8月22日',
      'members': 5,
    },
  ];

  final List<Map<String, dynamic>> strategies = [
    {
      'image':
          'http://www.luxunmuseum.com.cn/data/attached/4b5ce2fe28308fd9/image/20250415/17447007818454.jpg',
      'title': '鲁迅纪念馆参观攻略',
      'likes': 256,
    },
    {
      'image':
          'http://www.luxunmuseum.com.cn/data/attached/4b5ce2fe28308fd9/image/20250415/17447007818454.jpg',
      'title': '鲁迅纪念馆参观攻略',
      'likes': 256,
    },
    {
      'image':
          'http://www.luxunmuseum.com.cn/data/attached/4b5ce2fe28308fd9/image/20250415/17447007818454.jpg',
      'title': '鲁迅纪念馆参观攻略',
      'likes': 256,
    },
    {
      'image':
          'https://www.zunyihy.cn/n342/20220411/880/material/2f7caa1a-4c05-43c3-8482-461108fd9a40.jpg',
      'title': '遵义会议会址旅游攻略',
      'likes': 189,
    },
    {
      'image':
          'https://www.zunyihy.cn/n342/20220411/880/material/2f7caa1a-4c05-43c3-8482-461108fd9a40.jpg',
      'title': '遵义会议会址旅游攻略',
      'likes': 189,
    },
    {
      'image':
          'https://www.zunyihy.cn/n342/20220411/880/material/2f7caa1a-4c05-43c3-8482-461108fd9a40.jpg',
      'title': '遵义会议会址旅游攻略',
      'likes': 189,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 280,
            right: 2,
            child: DigitaPsersonFloatViewHome(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Card(
                child: SizedBox(
                  width: 300,
                  height: 180,
                  child: ContentWidget(
                    assetPath: 'assets/html/widgets/map.html',
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SectionTitle(title: '正在组队', action: '查看全部'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: teams.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) => TeamCard(team: teams[index]),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SectionTitle(title: '热门攻略', action: '更多推荐'),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => StrategyCard(strategy: strategies[index]),
                childCount: strategies.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiInputWidget extends StatefulWidget {
  const AiInputWidget({super.key});
  @override
  State<StatefulWidget> createState() {
    return _AiInputWidgetState();
  }
}

class _AiInputWidgetState extends State<AiInputWidget> {
  final TextEditingController inputControl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '小旅助手',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 60,
            width: 300,
            child: TextField(
              controller: inputControl,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                hint: Text(
                  '向小旅游助手提问',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: EdgeInsets.only(left: 30), child: Text('建议:')),
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 7,
                children: [
                  SizedBox(
                    width: 160,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 2, 2, 2),
                        child: Text(
                          '规划一下去遵义旅游的行程',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 2, 2, 2),
                        child: Text(
                          '最近热门',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 165,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 2, 2, 2),
                        child: Text(
                          '去红色场馆参观的注意事项',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall!.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(flex: 1, child: SizedBox(height: 1)),
            ],
          ),
        ],
      ),
    );
  }
}
