// lib/screens/test_screen.dart - ПОЛНОСТЬЮ ИСПРАВЛЕННЫЙ
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/user_provider.dart';
import '../core/providers/objects_provider.dart';
import '../models/question.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class TestScreen extends StatefulWidget {
  final String objectName;
  final int rewardCoins;
  final bool isHardTest;

  const TestScreen({
    super.key, 
    required this.objectName,
    this.rewardCoins = 20,
    this.isHardTest = false,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  int _correctAnswersCount = 0;
  bool _isFinished = false;
  bool _wasAlreadyCompleted = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final objectsProvider = Provider.of<ObjectsProvider>(context, listen: false);
    final object = objectsProvider.getObjectByName(widget.objectName);
    
    final userProvider = context.read<UserProvider>();
    await userProvider.loadUserData();
    
    final testKey = "${widget.objectName}_${widget.isHardTest ? "hard" : "simple"}";
    final alreadyCompleted = userProvider.isTestCompleted(testKey);
    
    if (kDebugMode) {
      debugPrint('=== TEST LOAD ===');
      debugPrint('Test key: $testKey');
      debugPrint('Already completed: $alreadyCompleted');
      debugPrint('=================');
    }
    
    setState(() {
      if (object != null) {
        if (widget.isHardTest) {
          _questions = object.hardQuestions;
        } else {
          _questions = object.simpleQuestions;
        }
      } else {
        _questions = [];
      }
      _isLoading = false;
      _wasAlreadyCompleted = alreadyCompleted;
    });
    
    _selectedAnswers = List<int?>.filled(_questions.length, null);
    
    if (_wasAlreadyCompleted == true && _questions.isNotEmpty) {
      for (int i = 0; i < _questions.length; i++) {
        _selectedAnswers[i] = _questions[i].correctIndex;
      }
      _correctAnswersCount = _questions.length;
      _isFinished = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showAlreadyCompletedDialog();
        }
      });
    }
    
    setState(() {});
  }

  void _updateCorrectAnswersCount() {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctIndex) {
        count++;
      }
    }
    _correctAnswersCount = count;
  }

  void _selectAnswer(int answerIndex) {
    if (_wasAlreadyCompleted == true || _isSaving == true) return;
    
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
      _updateCorrectAnswersCount();
      
      bool allAnswered = _selectedAnswers.every((a) => a != null);
      if (allAnswered == true && _isFinished == false) {
        _isFinished = true;
        
        if (_correctAnswersCount == _questions.length) {
          _saveTestResult();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showFailureDialog();
            }
          });
        }
      }
    });
  }

  void _restartTest() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers = List<int?>.filled(_questions.length, null);
      _correctAnswersCount = 0;
      _isFinished = false;
      _isSaving = false;
    });
  }

  void _goToQuestion(int index) {
    if (_wasAlreadyCompleted == true || _isSaving == true) return;
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  Future<void> _saveTestResult() async {
    if (_isSaving == true) return;
    
    _isSaving = true;
    if (mounted) setState(() {});
    
    final testKey = "${widget.objectName}_${widget.isHardTest ? "hard" : "simple"}";
    final userProvider = context.read<UserProvider>();
    
    await userProvider.loadUserData(forceRefresh: true);
    
    if (userProvider.isTestCompleted(testKey) == true) {
      if (kDebugMode) {
        debugPrint('Test already completed, not saving again');
      }
      if (mounted) {
        _isSaving = false;
        _showAlreadyCompletedDialog();
      }
      return;
    }
    
    int earnedCoins = _correctAnswersCount * widget.rewardCoins ~/ _questions.length;
    
    if (kDebugMode) {
      debugPrint('Saving test result. Earned coins: $earnedCoins');
    }
    
    try {
      final result = await userProvider.addCompletedTest(
        testKey: testKey,
        objectName: widget.objectName,
        testType: widget.isHardTest ? "hard" : "simple",
        earnedCoins: earnedCoins,
      );
      
      if (kDebugMode) {
        debugPrint('Save test result result: success=${result.success}, isDuplicate=${result.isDuplicate}');
      }
      
      if (mounted) {
        _isSaving = false;
        
        if (result.success == true) {
          setState(() {
            _wasAlreadyCompleted = true;
          });
          _showCongratulationsDialog(earnedCoins);
        } else if (result.isDuplicate == true) {
          _showAlreadyCompletedDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? "Ошибка при сохранении результата"),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving test: $e');
      }
      if (mounted) {
        _isSaving = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showCongratulationsDialog(int earnedCoins) {
    if (mounted == false) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFAD1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: AppDecorations.redGradientSquare,
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.whiteText,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Поздравляем! 🎉",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.itim25,
                ),
                const SizedBox(height: 16),
                Text(
                  "Вы прошли тест на 100%!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.beigeBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.beigeBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryRed),
                        ),
                        child: Icon(
                          Icons.check,
                          color: AppColors.primaryRed,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Вы заработали ",
                              style: TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: "$earnedCoins",
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: " монет!",
                              style: TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 200,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD34040),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Закрыть",
                        style: TextStyle(
                          color: AppColors.whiteText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAlreadyCompletedDialog() {
    if (mounted == false) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFAD1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: AppDecorations.redGradientSquare,
                  child: const Icon(
                    Icons.info,
                    color: AppColors.whiteText,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Тест уже пройден",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.itim25,
                ),
                const SizedBox(height: 16),
                Text(
                  "Вы уже проходили этот тест на 100% ранее!\nПравильных ответов: $_correctAnswersCount из ${_questions.length}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 200,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD34040),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text(
                        "Закрыть",
                        style: TextStyle(
                          color: AppColors.whiteText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFailureDialog() {
    if (mounted == false) return;
    
    int percentage = (_correctAnswersCount * 100) ~/ _questions.length;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFAD1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: AppDecorations.redGradientSquare,
                  child: const Icon(
                    Icons.sentiment_dissatisfied,
                    color: AppColors.whiteText,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Попробуйте еще раз",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.itim25,
                ),
                const SizedBox(height: 16),
                Text(
                  "Вы правильно ответили на $_correctAnswersCount из ${_questions.length} вопросов ($percentage%)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 120,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD34040),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Center(
                          child: Text(
                            "Выйти",
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _restartTest();
                      },
                      child: Container(
                        width: 120,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD34040),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.whiteText),
                        ),
                        child: const Center(
                          child: Text(
                            "Пройти еще раз",
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading == true) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Вопросы для этого теста не найдены",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Назад"),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSaving == true) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Сохранение результата...",
                style: TextStyle(color: AppColors.primaryRed, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final isFirstQuestion = _currentQuestionIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _TestHeader(
            objectName: widget.objectName,
            currentQuestion: _currentQuestionIndex + 1,
            totalQuestions: _questions.length,
            isHardTest: widget.isHardTest,
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.beigeBackground,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline15,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  ...List.generate(question.options.length, (index) {
                    bool isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                    bool isCorrect = index == question.correctIndex;
                    bool showResult = _selectedAnswers[_currentQuestionIndex] != null;
                    
                    Color backgroundColor;
                    if (showResult == true) {
                      if (isCorrect == true) {
                        backgroundColor = AppColors.greenCorrect;
                      } else if (isSelected == true && isCorrect == false) {
                        backgroundColor = AppColors.redWrong;
                      } else {
                        backgroundColor = AppColors.greyBackground;
                      }
                    } else {
                      backgroundColor = AppColors.greyBackground;
                    }
                    
                    Color borderColor;
                    if (showResult == true && isCorrect == true) {
                      borderColor = const Color(0xFF58F453);
                    } else if (showResult == true && isSelected == true && isCorrect == false) {
                      borderColor = const Color(0xFFC71C1C);
                    } else {
                      borderColor = AppColors.whiteText;
                    }
                    
                    return GestureDetector(
                      onTap: () {
                        if (_selectedAnswers[_currentQuestionIndex] == null && _isSaving == false) {
                          _selectAnswer(index);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
                        height: 54,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: AppTextStyles.blueText20,
                              ),
                            ),
                            if (showResult == true && isCorrect == true)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenCorrect,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF58F453), width: 1),
                                  ),
                                  child: const Icon(Icons.check, color: Color(0xFF58F453), size: 16),
                                ),
                              ),
                            if (showResult == true && isSelected == true && isCorrect == false)
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.redWrong,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFC71C1C), width: 1),
                                  ),
                                  child: const Icon(Icons.close, color: Color(0xFFC71C1C), size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  const Spacer(),
                  
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 38),
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.greyBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Правильных ответов",
                          style: AppTextStyles.blueText15,
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "$_correctAnswersCount/${_questions.length}",
                          style: AppTextStyles.blueText20,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 38),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isFirstQuestion == false)
                          _NavButton(
                            text: "Назад",
                            isBack: true,
                            onTap: () => _goToQuestion(_currentQuestionIndex - 1),
                          )
                        else
                          const SizedBox(width: 94),
                        
                        if (isLastQuestion == false)
                          _NavButton(
                            text: "Далее",
                            isBack: false,
                            onTap: () => _goToQuestion(_currentQuestionIndex + 1),
                          )
                        else
                          const SizedBox(width: 94),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_questions.length, (index) {
                        bool isAnswered = _selectedAnswers[index] != null;
                        bool isCurrent = _currentQuestionIndex == index;
                        
                        return GestureDetector(
                          onTap: () => _goToQuestion(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isAnswered == true ? AppColors.darkRed : AppColors.greyBackground,
                              shape: BoxShape.circle,
                              border: isCurrent == true ? Border.all(color: AppColors.primaryRed, width: 3) : null,
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: isAnswered == true ? AppColors.whiteText : AppColors.blueText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          const _CustomBottomNavBar(),
        ],
      ),
    );
  }
}

// ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ (остаются без изменений)
class _TestHeader extends StatelessWidget {
  final String objectName;
  final int currentQuestion;
  final int totalQuestions;
  final bool isHardTest;

  const _TestHeader({
    required this.objectName,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.isHardTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 105,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 9,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.39),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.whiteText, size: 16),
              ),
            ),
          ),
          
          Positioned(
            left: 31,
            top: 33,
            child: Text(
              isHardTest == true ? "Сложный тест: $objectName" : "Тест: $objectName",
              style: AppTextStyles.headline25,
            ),
          ),
          
          Positioned(
            left: 23,
            top: 70,
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(text: "Вопрос ", style: AppTextStyles.headline12),
                  TextSpan(text: "$currentQuestion ", style: AppTextStyles.headline15),
                  const TextSpan(text: "из ", style: AppTextStyles.headline12),
                  TextSpan(text: "$totalQuestions", style: AppTextStyles.headline15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String text;
  final bool isBack;
  final VoidCallback onTap;

  const _NavButton({
    required this.text,
    required this.isBack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 94,
        height: 25,
        decoration: BoxDecoration(
          color: const Color(0xFFCC6665),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD3514A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBack == true) const Icon(Icons.arrow_back_ios, color: Color(0xFFFAF0F0), size: 10),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: Color(0xFFFAF0F0), fontSize: 12, fontWeight: FontWeight.w800)),
            if (isBack == false) const Icon(Icons.arrow_forward_ios, color: Color(0xFFFAF0F0), size: 10),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  const _CustomBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      decoration: const BoxDecoration(
        color: AppColors.primaryRed,
        boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(0, -2), blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.qr_code_scanner, label: "Сканер", index: 0),
          _NavItem(icon: Icons.map, label: "Карта", index: 1),
          _NavItem(icon: Icons.menu, label: "Меню", index: 2),
          _NavItem(icon: Icons.person, label: "Профиль", index: 3),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({required this.icon, required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
