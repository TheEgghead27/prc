static final int MARGIN = 6;
class Display {
  private int x, y;  // top-left corner
  private int dispWidth = 80, dispHeight = 24;  // width and height in un-spaced characters, disp prefix to avoid namespace collisions with global variables
  private int offset = 0;  // offset from start N lines to allow for scrolling
  private ArrayList<Text> lines = new ArrayList<Text>();
  private static final int FRAMES = 5;  // re-render N times to account for Processing failing to draw correctly
  private int needsRerender = FRAMES - 1;

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

  public int removeLine(Text line) {
    for (int i = 0; i < lines.size(); i++) {
      if (lines.get(i).equals(line)) {
        lines.remove(i);
        markRerender();
        return i;
      }
    }
    return -1;
  }

  public void clear() {
    while (lines.size() > 0)
      lines.remove(0);
    markRerender();
  }

  public void reposition(int x, int y) {
    this.x = x;
    this.y = y;
  }

  public void resize(int w, int h) {
      dispWidth = w;
      dispHeight = h;
  }

  public void addOffset(int o) {
    offset += o;
    if (offset < 0) offset = 0;
    else if (offset >= lines.size()) offset = lines.size() - 1;
    markRerender();
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
    fill(Text.bgColor);
    stroke(Text.textColor);
    int finalWidth = (int)(dispWidth * Text.fontWidth + 2 * MARGIN);
    int finalHeight = (int)(dispHeight * Text.fontSize + 2 * MARGIN);
    rect(x, y, finalWidth, finalHeight);
    int pX = x + MARGIN;
    int pY = y + MARGIN;
    for (int i = offset; i < lines.size(); i++) {
      pY += ((lines.get(i).display(pX, pY, x + finalWidth, y + finalHeight, dispWidth))[0] + Text.lineSpace) * Text.fontSize;
    }
    return new float[]{
      x + dispWidth * Text.fontWidth + 2 * MARGIN,
      y + dispHeight * Text.fontSize + 2 * MARGIN
    };
  }
}
