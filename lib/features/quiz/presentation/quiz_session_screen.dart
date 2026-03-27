import 'package:acad_mate/app/providers.dart';
import 'package:acad_mate/core/theme/app_colors.dart';
import 'package:acad_mate/core/widgets/glass_card.dart';
import 'package:acad_mate/core/widgets/gradient_backdrop.dart';
import 'package:acad_mate/domain/entities/question.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  const QuizSessionScreen({super.key, required this.setId});

  final String setId;

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  int _index = 0;
  int? _selectedOption;
  int _score = 0;
  bool _answered = false;
  bool _complete = false;

  void _selectAnswer(Question question, int optionIndex) {
    if (_answered || _complete) {
      return;
    }

    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
      if (optionIndex == question.correctIndex) {
        _score += 1;
      }
    });
  }

  void _nextQuestion(QuestionSet set) {
    if (_index >= set.questions.length - 1) {
      setState(() => _complete = true);
      return;
    }

    setState(() {
      _index += 1;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selectedOption = null;
      _score = 0;
      _answered = false;
      _complete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionSetAsync = ref.watch(questionSetProvider(widget.setId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz session')),
      body: GradientBackdrop(
        child: questionSetAsync.when(
          data: (QuestionSet? set) {
            if (set == null || set.questions.isEmpty) {
              return const Center(
                child: GlassCard(child: Text('Question set not found.')),
              );
            }

            if (_complete) {
              return _QuizResult(set: set, score: _score, onRetry: _restart);
            }

            final int total = set.questions.length;
            final int safeIndex = _index.clamp(0, total - 1);
            final Question question = set.questions[safeIndex];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: <Widget>[
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _LabelChip(text: set.grade, color: AppColors.primary),
                          const SizedBox(width: 8),
                          _LabelChip(text: set.subject, color: set.accentColor),
                          const Spacer(),
                          Text(
                            '${safeIndex + 1}/$total',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: (safeIndex + 1) / total,
                          backgroundColor: AppColors.border.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        questionSetTitle(set),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: set.accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.prompt,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Column(
                    key: ValueKey<String>(question.id),
                    children: <Widget>[
                      ...List<Widget>.generate(question.options.length, (
                        int optionIndex,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionTile(
                            index: optionIndex,
                            text: question.options[optionIndex],
                            selected: _selectedOption == optionIndex,
                            answered: _answered,
                            correctIndex: question.correctIndex,
                            onTap: () => _selectAnswer(question, optionIndex),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (_answered) ...<Widget>[
                  const SizedBox(height: 4),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _selectedOption == question.correctIndex
                              ? 'Correct'
                              : 'Not quite',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _selectedOption == question.correctIndex
                                    ? AppColors.success
                                    : AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _answered ? () => _nextQuestion(set) : null,
                    child: Text(
                      safeIndex == total - 1 ? 'Finish quiz' : 'Next question',
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) =>
              Center(child: GlassCard(child: Text(error.toString()))),
        ),
      ),
    );
  }
}

String questionSetTitle(QuestionSet set) {
  return '${set.topic} • ${set.estimatedMinutes} min';
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.answered,
    required this.correctIndex,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool answered;
  final int correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isCorrect = index == correctIndex;
    final bool isWrongChoice = answered && selected && !isCorrect;
    final bool showCorrect = answered && isCorrect;

    Color borderColor = AppColors.border;
    Color backgroundColor = colors.surface;
    Color iconColor = AppColors.textMuted;

    if (selected) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: 0.08);
      iconColor = AppColors.primary;
    }
    if (showCorrect) {
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.12);
      iconColor = AppColors.success;
    }
    if (isWrongChoice) {
      borderColor = AppColors.danger;
      backgroundColor = AppColors.danger.withValues(alpha: 0.12);
      iconColor = AppColors.danger;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          if (selected || showCorrect || isWrongChoice)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  showCorrect
                      ? Icons.check_circle_rounded
                      : isWrongChoice
                      ? Icons.cancel_rounded
                      : selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.circle_outlined,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 240.ms).slideX(begin: 0.03, end: 0);
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuizResult extends StatelessWidget {
  const _QuizResult({
    required this.set,
    required this.score,
    required this.onRetry,
  });

  final QuestionSet set;
  final int score;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final int total = set.questions.length;
    final double accuracy = total == 0 ? 0 : score / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: <Widget>[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Session complete',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _ResultCircle(
                    value: '${(accuracy * 100).round()}%',
                    label: 'Accuracy',
                    accent: set.accentColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '$score / $total correct',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You finished ${set.title} and can retry to beat your score.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _SummaryChip(label: 'Grade', value: set.grade),
            _SummaryChip(label: 'Subject', value: set.subject),
            _SummaryChip(label: 'Topic', value: set.topic),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Next steps',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Try a different stream, review explanations, or move to past papers for exam-style repetition.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Retry this set')),
      ],
    );
  }
}

class _ResultCircle extends StatelessWidget {
  const _ResultCircle({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
