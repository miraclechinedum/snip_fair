part of 'toggle_tab.dart';

/// This constant function to distribute reuse function
double _widthInPercent(double percent, BuildContext context) {
  final toDouble = percent / 100;
  return MediaQuery.of(context).size.width * toDouble;
}

const BoxShadow bsInner = BoxShadow(
  color: Colors.black12,
  offset: Offset(0, 1.5),
  blurRadius: 1,
  spreadRadius: -1,
);
const BoxShadow bsOuter = BoxShadow(
  color: Colors.black12,
  offset: Offset(0, 1.5),
  blurRadius: 1,
  spreadRadius: 1,
);

const BoxDecoration bdHeader = BoxDecoration(boxShadow: [bsOuter]);
