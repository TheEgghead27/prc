static abstract class TextConstants {
  // PRECONDITION: All PFonts are initialized externally in setup()
  static PFont regular, bold, italic;
  static color textColor;
  static int fontSize;
  static float fontWidth;
  static float lineSpace;
}
abstract class Text extends TextConstants {
  // width in characters, assuming monospace font
  abstract int[] display(int x1, int y1, int x2, int y2, int w);

  boolean equals(Text other) {
    return this.toString().equals(other.toString());
  }

  int[] display(int x1, int y1, int x2, int y2, int w, String s, color c, PFont font) {
    textFont(font);
    return display(x1, y1, x2, y2, w, s, c);
  }
  int[] display(int x1, int y1, int x2, int y2, int w, String s, color c) {
    fill(c);
    return display(x1, y1, x2, y2, w, s);
  }
  // (x1, y1) are the top corner of the bounding box, (x2, y2) for the second
  int[] display(int x1, int y1, int x2, int y2, int w, String s) {
    int rows = 0;  // number of character rows
    int remain = 0;  // number of characters printed in last row

    for (int i = 0; i < s.length(); i += w) {
      if (y2 < y1) break;
      String line = s.substring(i, Math.min(i+w, s.length()));
      text(line, x1, y1, x2 - x1, y2 - y1);
      y1 += fontSize;
      rows++;
      remain = line.length();
    }
    return new int[]{
      rows,
      remain,
      s.length()
    };
  }
}

color colors[] = new color[]{
  #FF8800,
  #FF2222,
  #00FF00,
  #00FF88,
  #0088FF,
  #FF00FF
};

class User extends Text {
  private String username;
  private String hostname = "localhost";
  private String fullname;
  private color userColor;

  public User(String user) {
    username = user;
    regenerate();
  }
  public User(String user, String host) {
    username = user;
    hostname = host;
    regenerate();
  }

  int[] display(int x1, int y1, int x2, int y2, int w) {
    return display(x1, y1, x2, y2, w, fullname, userColor, bold);
  }
  public String getUsername() {
    return username;
  }
  public String getHostname() {
    return hostname;
  }
  public boolean setUsername(String newUsername) {
    if (newUsername != null) {
      username = newUsername;
      regenerate();
      return true;
    }
    return false;
  }
  private void regenerate() {
    fullname = toString();
    int a = 0;
    for (int i = 0; i < fullname.length(); i++) {
      a += fullname.charAt(i) * i;
    }
    userColor = colors[a % colors.length];
  }
  String toString() {
    if (hostname == null) return username;
    return username + '@' + hostname;
  }
}

class Message extends Text {
  private User author;
  private String content;

  public Message(User a, String c) {
    author = a;
    content = c;
  }

  int[] display(int x1, int y1, int x2, int y2, int w) {
    String disp = content;
    int[] ret, tmp;
    ret = author.display(x1, y1, x2, y2, w);
    y1 += ret[0] * fontSize;
    if (ret[1] > 1) {  // username (+ 1 space) did not take up full row
      // move back a row
      y1 -= fontSize;
      ret[0]--;

      disp = new String(new char[ret[1] + 1]).replace('\0', ' ') + disp; // skip the chars in the last row + 1 space
    }

    tmp = display(x1, y1, x2, y2, w, disp, textColor, regular);
    ret[0] += tmp[0];
    ret[1] = tmp[1];
    return ret;
  }
  public User getAuthor() {
    return author;
  }
  public String getContent() {
    return content;
  }
  public String toString() {
    return content;
  }
}

class Channel extends Text {
  private String name;
  public Channel(String n) {
    name = n;
  }

  String getName() {
    return name;
  }

  public String toString() {
    return "#" + name;
  }

  int[] display(int x1, int y1, int x2, int y2, int w) {
    return display(x1, y1, x2, y2, w, toString(), textColor, bold);
  }
}


class Input extends Text {
  String content = "";
  int inputWidth = 40;
  public Input() {}
  public Input(int w) {
    inputWidth = w;
  }
  int[] display(int x1, int y1, int x2, int y2, int w) {
    String buf = content + '_';
    if (buf.length() > w)
      buf = buf.substring(buf.length() - w);
    return display(x1, y1, x2, y2, w, buf, textColor, regular);
  }
  public String toString() {
    return content;
  }
}
