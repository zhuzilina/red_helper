import 'package:flutter/foundation.dart';
import '../repository/api/question_answer_api.dart';
import '../utils/global_oauth_manager.dart';

class QuestionAnswerProvider extends ChangeNotifier {
  // 问题解答服务
  late QuestionAnswerService _questionAnswerService;

  // 问题解答数据缓存
  final Map<String, QuestionAnswerResponse> _answerCache = {};

  // 加载状态缓存
  final Map<String, bool> _loadingStates = {};

  // 错误状态缓存
  final Map<String, String?> _errorStates = {};

  // 构造函数
  QuestionAnswerProvider() {
    _initService();
  }

  // 初始化服务
  void _initService() {
    try {
      final oAuthManager = GlobalOAuthManager();
      _questionAnswerService = QuestionAnswerService(oAuthManager);
      print("✅ QuestionAnswerProvider 初始化成功");
    } catch (e) {
      print("❌ QuestionAnswerProvider 初始化失败: $e");
    }
  }

  // 延迟初始化服务（用于确保OAuth服务已准备就绪）
  Future<void> _ensureServiceInitialized() async {
    if (_questionAnswerService == null) {
      try {
        final oAuthManager = GlobalOAuthManager();
        _questionAnswerService = QuestionAnswerService(oAuthManager);
        print("✅ QuestionAnswerProvider 延迟初始化成功");
      } catch (e) {
        print("❌ QuestionAnswerProvider 延迟初始化失败: $e");
        throw e;
      }
    }
  }

  // 获取问题解答（带缓存）
  Future<QuestionAnswerResponse?> getAnswer(
    String question, {
    bool forceRefresh = false,
  }) async {
    // 生成问题ID（用于缓存键）
    final questionId = _generateQuestionId(question);

    // 如果正在加载且不强制刷新，直接返回
    if (_loadingStates[questionId] == true && !forceRefresh) {
      print("🔄 问题正在加载中: $questionId");
      return _answerCache[questionId];
    }

    // 如果已有缓存且不强制刷新，直接返回
    if (_answerCache.containsKey(questionId) && !forceRefresh) {
      print("📋 从缓存获取解答: $questionId");
      return _answerCache[questionId];
    }

    // 确保服务已初始化
    await _ensureServiceInitialized();

    // 开始加载
    _setLoadingState(questionId, true);
    _clearErrorState(questionId);

    try {
      print("🚀 开始获取问题解答: $questionId");

      // 调用API获取解答
      final answer = await _questionAnswerService.getAnswer(question);

      // 缓存结果
      _answerCache[questionId] = answer;
      _setLoadingState(questionId, false);

      print("✅ 问题解答获取成功: $questionId");
      return answer;
    } catch (e) {
      print("❌ 获取问题解答失败: $questionId - $e");
      _setErrorState(questionId, e.toString());
      _setLoadingState(questionId, false);
      return null;
    }
  }

  // 预加载问题解答（不等待结果）
  void preloadAnswer(String question) {
    final questionId = _generateQuestionId(question);

    // 如果已经在加载或已有缓存，跳过
    if (_loadingStates[questionId] == true ||
        _answerCache.containsKey(questionId)) {
      print("⏭️ 跳过预加载: $questionId (已在加载或已有缓存)");
      return;
    }

    print("🔄 预加载问题解答: $questionId");
    print(
      "📝 问题内容: ${question.substring(0, question.length > 30 ? 30 : question.length)}...",
    );

    // 异步执行，不阻塞UI
    Future.microtask(() async {
      try {
        await getAnswer(question);
      } catch (e) {
        print("❌ 预加载失败: $questionId - $e");
      }
    });
  }

  // 批量预加载问题解答
  void preloadAnswers(List<String> questions) {
    for (final question in questions) {
      preloadAnswer(question);
    }
  }

  // 获取加载状态
  bool isLoading(String question) {
    final questionId = _generateQuestionId(question);
    return _loadingStates[questionId] == true;
  }

  // 获取错误状态
  String? getError(String question) {
    final questionId = _generateQuestionId(question);
    return _errorStates[questionId];
  }

  // 获取缓存的解答
  QuestionAnswerResponse? getCachedAnswer(String question) {
    final questionId = _generateQuestionId(question);
    return _answerCache[questionId];
  }

  // 清除缓存
  void clearCache() {
    _answerCache.clear();
    _loadingStates.clear();
    _errorStates.clear();
    notifyListeners();
    print("🗑️ 问题解答缓存已清除");
  }

  // 清除特定问题的缓存
  void clearQuestionCache(String question) {
    final questionId = _generateQuestionId(question);
    _answerCache.remove(questionId);
    _loadingStates.remove(questionId);
    _errorStates.remove(questionId);
    notifyListeners();
    print("🗑️ 问题缓存已清除: $questionId");
  }

  // 刷新特定问题的解答
  Future<QuestionAnswerResponse?> refreshAnswer(String question) async {
    return await getAnswer(question, forceRefresh: true);
  }

  // 设置加载状态
  void _setLoadingState(String questionId, bool isLoading) {
    _loadingStates[questionId] = isLoading;
    notifyListeners();
  }

  // 设置错误状态
  void _setErrorState(String questionId, String error) {
    _errorStates[questionId] = error;
    notifyListeners();
  }

  // 清除错误状态
  void _clearErrorState(String questionId) {
    _errorStates.remove(questionId);
    notifyListeners();
  }

  // 生成问题ID（用于缓存键）
  String _generateQuestionId(String question) {
    // 使用问题的哈希值作为ID，确保相同问题使用相同缓存
    return question.hashCode.toString();
  }

  // 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': _answerCache.length,
      'totalLoading': _loadingStates.values.where((loading) => loading).length,
      'totalErrors': _errorStates.length,
    };
  }

  // 调试方法：打印缓存详情
  void debugCache() {
    print("🔍 缓存调试信息:");
    print("  缓存数量: ${_answerCache.length}");
    print(
      "  加载中数量: ${_loadingStates.values.where((loading) => loading).length}",
    );
    print("  错误数量: ${_errorStates.length}");

    if (_answerCache.isNotEmpty) {
      print("  缓存的问题ID:");
      _answerCache.keys.forEach((key) {
        final answer = _answerCache[key];
        print("    $key -> ${answer?.answer.length ?? 0} 字符");
      });
    }
  }

  // 检查是否有任何问题正在加载
  bool get hasAnyLoading {
    return _loadingStates.values.any((loading) => loading);
  }

  // 获取所有正在加载的问题
  List<String> get loadingQuestions {
    return _loadingStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}
