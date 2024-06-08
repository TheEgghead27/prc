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
  abstract int[] display(int x, int y, int w);
  abstract String toString();
  
  boolean equals(Text other) {
    return this.toString().equals(other.toString());
  }
  int[] display(int x, int y, int w, String s, color c, PFont font) {
    textFont(font);
    return display(x, y, w, s, c);
  }
  int[] display(int x, int y, int w, String s, color c) {
    fill(c);
    return display(x, y, w, s);
  }
  int[] display(int x, int y, int w, String s) {
    int rows = 0;  // number of character rows
    int remain = 0;  // number of characters printed in last row

    for (int i = 0; i < s.length(); i += w) {
      String line = s.substring(i, Math.min(i+w, s.length()));
      text(line, x, y + rows * fontSize);
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

  int[] display(int x, int y, int w) {
    return display(x, y, w, fullname, userColor, bold);
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

  int[] display(int x, int y, int w) {
    String disp = content;
    int[] ret, tmp;
    ret = author.display(x, y, w);
    y += ret[0] * fontSize;
    if (ret[1] > 1) {  // username (+ 1 space) did not take up full row
      // move back a row
      y -= fontSize;
      ret[0]--;

      disp = new String(new char[ret[1] + 1]).replace('\0', ' ') + disp; // skip the chars in the last row + 1 space
    }

    tmp = display(x, y, w, disp, textColor, regular);
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

  int[] display(int x, int y, int w) {
    String disp = toString();
    return display(x, y, w, disp, textColor, bold);
  }

  public String toString() {
    return "#" + name;
  }
}


class Input extends Text {
  String content = "";
  int[] display(int x, int y, int w) {
    return display(x, y, w, content + '_', textColor, regular);
  }
  public String toString() {
    return content;
  }
}
