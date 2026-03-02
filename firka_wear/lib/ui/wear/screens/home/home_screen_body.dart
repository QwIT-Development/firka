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

class _PlaceholderPage extends StatelessWidget {
  final int index;
  final double viewportHeight;

  const _PlaceholderPage({required this.index, required this.viewportHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: viewportHeight,
      child: Center(
        child: Text(
          'Placeholder $index',
          style: TextStyle(
            color: wearStyle.colors.textPrimary,
            fontSize: 14,
            fontFamily: 'Montserrat',
            fontVariations: [FontVariation('wght', 400)],
          ),
        ),
      ),
    );
  }
}
