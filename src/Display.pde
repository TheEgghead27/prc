class Display {
  private static final int MARGIN = 8;
  private int x = 0, y = 0;
  private int dispWidth = 80, dispHeight = 24;  // width and height in characters, disp prefix to avoid namespace collisions with global variables
  private ArrayList<Text> lines = new ArrayList<Text>();

  public Display() {}
  public Display(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    dispWidth = w;
    dispHeight = h;
  }

  public void addLine(Text line) {
    lines.add(line);
  }

  public void reposition(int x, int y) {
    this.x = x;
    this.y = y;
  }
  public void resize(int w, int h) {
      dispWidth = w;
      dispHeight = h;
  }

  public float[] display() {
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
