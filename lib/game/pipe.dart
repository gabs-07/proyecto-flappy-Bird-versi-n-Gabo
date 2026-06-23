class Pipe {
  double x;
  double gapY;
  double gapHeight;
  bool scored;

  Pipe({
    required this.x,
    required this.gapY,
    required this.gapHeight,
    this.scored = false,
  });
}
