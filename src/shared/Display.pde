static final int MARGIN = 6;
class Display {
  private int x = 0, y = 0;
  private int dispWidth = 80, dispHeight = 24;  // width and height in characters, disp prefix to avoid namespace collisions with global variables
  private ArrayList<Text> lines = new ArrayList<Text>();
  private static final int FRAMES = 10;
  int needsRerender = FRAMES - 1;

  public Display() {}
  public Display(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    dispWidth = w;
    dispHeight = h;
  }

  public void addLine(Text line) {
    lines.add(line);
    markRerender();
  }
  public void removeLine() {
    if (lines.size() > 0)
      lines.remove(0);
  }
  public boolean removeLine(Text line) {
    for (int i = 0; i < lines.size(); i++) {
      if (lines.get(i).equals(line)) {
        lines.remove(i);
        return true;
      }
    }
    return false;
  }

  public void reposition(int x, int y) {
    this.x = x;
    this.y = y;
  }
  public void resize(int w, int h) {
      dispWidth = w;
      dispHeight = h;
  }
  public int getX() {
    return x;
  }
  public int getY() {
    return y;
  }
  public void markRerender() {
    needsRerender = 0;
  }

  public float[] display() {
    if (needsRerender >= FRAMES) return new float[]{0,0};
    needsRerender++;
    fill(0);
    stroke(255);
    rect(x, y, dispWidth * Text.fontWidth + 2 * MARGIN, dispHeight * Text.fontSize + 2 * MARGIN);
    int pX = x + MARGIN;
    int pY = y + MARGIN;
    for (Text line: lines) {
      pY += ((line.display(pX, pY, dispWidth))[0] + Text.lineSpace) * Text.fontSize;
    }
    return new float[]{
      x + dispWidth * Text.fontWidth + 2 * MARGIN,
      y + dispHeight * Text.fontSize + 2 * MARGIN
    };
  }
}
