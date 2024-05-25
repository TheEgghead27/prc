class Display {
  private static final int MARGIN = 8;
  private int x, y;
  private int dispWidth, dispHeight;  // width and height in characters, disp prefix to avoid namespace collisions with global variables
  private ArrayList<Text> lines;
  public Display(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    dispWidth = w;
    dispHeight = h;
    lines = new ArrayList<Text>();
  }
  public void addLine(Text line) {
    lines.add(line);
  }
  public void display() {
    fill(0);
    stroke(255);
    rect(x, y, dispWidth * Text.fontWidth + 2 * MARGIN, dispHeight * Text.fontSize + 2 * MARGIN);
    int pX = x + MARGIN;
    int pY = y + MARGIN;
    for (Text line: lines) {
      pY += ((line.display(pX, pY, dispWidth))[0] + Text.lineSpace) * Text.fontSize;
    }
  }
}
