import 'package:flutter/material.dart';
import 'package:red_helper/route/routes.dart';

class AIPage extends StatefulWidget {
  final dynamic arguments;

  const AIPage({super.key, required this.arguments});

  @override
  State<AIPage> createState() => _AIPageState();
}

class Paragraph {
  final String content;
  final num type;
  Paragraph(this.content, this.type);

  factory Paragraph.fromJson(Map<String, dynamic> json) {
    return Paragraph(json['content'], json['label']);
  }
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, dynamic>> data = [
    {"label": 1, "content": "宝子们👫，今天小新要给同为红色文化爱好者的你，好好介绍一下超有魅力的瑞金！"},
    {
      "label": 2,
      "content":
          "瑞金位于江西省东南边陲，名字就超有寓意，因 “掘地得金、金为瑞” 得名。这里历史悠久，从唐天祐元年（904 年）置瑞金监，到南唐保大十一年（953 年）升监为县，至今已有一千多年历史啦。1931 - 1934 年它可是苏维埃中央政府直属县，还曾改名 “瑞京”，1994 年撤县设市，2014 年被列为省直管县（市）综合体制改革试点。",
    },
    {"label": 0, "content": "🌟红都圣地，意义非凡"},
    {
      "label": 2,
      "content":
          "上世纪 20 年代末 30 年代初，毛泽东等老一辈无产阶级革命家在这开辟了中央革命根据地，创立中华苏维埃共和国，开启治国理政伟大实践。党的群众路线、苏区精神等宝贵精神财富在此孕育，也是毛泽东思想重要形成地。党史专家用 “上海建党，开天辟地；南昌建军，惊天动地；瑞金建政，翻天覆地；北京建国，改天换地”，高度概括了瑞金在中国革命史和中共党史上的重要地位。这里是红色故都、共和国摇篮，还是中央红军长征出发地、人民代表大会制度初始发祥地、党和国家初心使命重要起源地。像沙洲坝下肖区七堡乡第三村农民杨荣显，将 8 个儿子送上革命前线，全部英勇牺牲；叶坪华屋 17 名青壮年男子出征前栽下松树，却都没能归来，这些故事都太令人动容了😭",
    },
    {
      "label": 3,
      "content":
          "瑞金保存着原生态革命旧址 129 处，全国重点文物保护单位就有 4 处共 37 个点。中央和国家 54 个部委机关都能在这里找到 “前身”，纷纷建立革命传统教育基地。你可以去叶坪革命旧址群，这里是中华苏维埃第一次全国代表大会会址所在地，能看到毛主席旧居等；还有沙洲坝革命旧址群，著名的红井就在这，“吃水不忘挖井人” 的故事就源于此，一定要去尝尝红井水，清甜无比。在这诵读《吃水不忘挖井人》，感受会更加深刻哦。近几年，当地还把 “开学第一课” 搬到红色旧址，组织中小学生演绎红色故事，比如 “苏区精神永放光芒” 情景故事讲演青少年版，让红色文化薪火相传🔥",
    },
    {"label": 0, "content": "🎨红色文化，创新传播"},
    {
      "label": 2,
      "content":
          "瑞金不仅有深厚底蕴，在红色文化传播上也超有创意。和功夫动漫公司合作打造红色基因传承超级 IP《少年家国梦》，通过动漫形式让孩子们轻松了解苏区革命历史，前 26 集已获得发行许可证，预计不久就能上线啦。北京舞蹈学院还复排了中央苏区红色歌舞，举办学术性复排展演，让红色文化以更多样的形式展现在大家眼前。而且瑞金积极打造红色题材最佳拍摄地，吸引了《长征》《红色摇篮》等 20 多部影视剧来取景拍摄🎬",
    },
    {"label": 0, "content": "🌳生态优美，物产丰富"},
    {
      "label": 2,
      "content":
          "瑞金位于赣江源头，生态环境超优越，是中国绿色名县、省级森林城市、卫生城市。森林覆盖率达 75.76%，空气优良率达 98.5%。设有赣江源国家级自然保护区，绵江湿地列为国家湿地公园（试点）。这里农业物产富饶，盛产脐橙、油茶、蔬菜、白莲等。“瑞金茶油” 是国家地理标志证明商标，“廖奶奶咸鸭蛋” 为代表的瑞金咸鸭蛋获批国家地理标志保护产品，武夷源茶叶还是中国驰名商标呢，来这可以尽情品尝特色美食😋",
    },
    {"label": 0, "content": "🏞️旅游胜地，多彩风景"},
    {
      "label": 3,
      "content":
          "瑞金旅游资源丰富得很！共和国摇篮景区是国家 5A 级景区，罗汉岩景区有 “江南小九寨” 美誉，奇峰罗列、怪石嶙峋、飞瀑流泉；铜钵山有 “绵江第一峰” 之称，林木葱郁，还有红军留下的遗迹。除了红色景点和自然风光，瑞金还是千年客家古邑，有数量可观的传统客家古村落，存有宋朝古宗祠、清代古牌楼等客家建筑群 200 余处、国家级传统古村落 6 个，瑞金民歌、传统竹编等各级非遗项目 133 个，能让你感受到独特的客家文化魅力。",
    },
    {
      "label": 1,
      "content":
          "宝子们，瑞金真的是一座超值得一去的城市，无论是探寻红色记忆，还是感受自然风光与客家文化，都能收获满满。收拾行囊，来瑞金开启一场红色文化之旅吧🧳",
    },
    {"label": 0, "content": "#瑞金 #红色文化 #旅游打卡 #红色故都 #共和国摇篮"},
    {"label": 1, "content": "如果你有特别想去的景点，或是对瑞金的美食、住宿感兴趣，都能告诉我，我可以给你更详细的攻略。\n"},
  ];
  late List<Paragraph> contents =
      data.map((item) => Paragraph.fromJson(item)).toList();
  @override
  void initState() {
    super.initState();
    // _args = widget.arguments as Map<String,dynamic>;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('美丽的瑞金'),
        backgroundColor: const Color(0xffBA0C2F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 内容列表（可滚动部分）
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(15, 25, 15, 0),
              itemCount: contents.length,
              itemBuilder: (context, index) {
                final content = contents[index];
                if (content.type > 1) {
                  return buttonItem(content, context);
                } else {
                  return textItem(content, context);
                }
              },
            ),
          ),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '问问AI',
                      prefixIcon: const Icon(
                        Icons.question_answer,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final searchText = _searchController.text;
                    if (searchText.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        RoutePath.assistant,
                        arguments: {'prompt': '请以小红书文案的形式为我解答该$searchText内容'},
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffBA0C2F),
                    minimumSize: const Size(56, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buttonItem(Paragraph content, BuildContext context) {
  // 带按钮的组件
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        "    ${content.content}",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ), // 段落内容
      buttonCustom(content, context), // 按钮
    ],
  );
}

Widget textItem(Paragraph content, BuildContext context) {
  // 文段组件
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (content.type == 1)
        Text(
          "    ${content.content}",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      if (content.type == 0)
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Text(
            content.content,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
    ],
  );
}

Widget buttonCustom(Paragraph content, BuildContext context) {
  // 按钮组件
  return ElevatedButton(
    // 按钮
    onPressed:
        () => Navigator.pushNamed(
          context,
          RoutePath.assistant,
          arguments: {
            if (content.type == 2) 'prompt': '请以小红书文案的形式解读${content.content}',
            if (content.type == 3)
              'prompt': '请以小红书文案的形式为我生成该内容：${content.content}的攻略',
          },
        ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent, // 背景透明
      elevation: 0, // 移除阴影
      shadowColor: Colors.transparent, // 阴影颜色透明
      shape: RoundedRectangleBorder(
        side: BorderSide.none, // 移除边框
      ),
      overlayColor: Colors.white10,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          content.type == 2 ? '文段解读' : '旅游攻略',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ), // 手动设置文字颜色
        ),
        const Icon(Icons.arrow_forward, color: Colors.red, size: 24),
      ],
    ),
  );
}
