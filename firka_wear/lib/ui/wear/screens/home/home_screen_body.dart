part of 'home_screen.dart';

class _HomeScreenBodyPage extends StatelessWidget {
  final List<Widget> body;
  final double padding;
  final double viewportHeight;

  const _HomeScreenBodyPage({
    required this.body,
    required this.padding,
    required this.viewportHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: viewportHeight,
      child: Container(
        padding: EdgeInsets.only(top: padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [...body],
        ),
      ),
    );
  }
}

class _LessonCardPage extends StatelessWidget {
  final Lesson? lesson;
  final double viewportHeight;

  const _LessonCardPage({
    required this.lesson,
    required this.viewportHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson == null) {
      return SizedBox(height: viewportHeight);
    }

    return SizedBox(
      height: viewportHeight,
      child: Center(
        child: SizedBox(
          width: 340.w,
          child: LessonCardSmall.fromLesson(lesson!),
        ),
      ),
    );
  }
}
