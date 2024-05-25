static abstract class TextConstants {
  // PRECONDITION: All PFonts are initialized externally in setup()
  static PFont regular, bold, italic;
  static color textColor;
  static int fontSize;
  static float lineWidth;
}
abstract class Text extends TextConstants {
  // width in characters, assuming monospace font
  abstract int[] display(int x, int y, int w);

  int[] display(int x, int y, int w, String s, color c, PFont font) {
    textFont(font);
    return display(x, y, w, s, c);
  }
  int[] display(int x, int y, int w, String s, color c) {
    fill(c);
    return display(x, y, w, s);
  }
  int[] display(int x, int y, int w, String s) {
    float rows = 0;
    int cols = 0;
    for (int i = 0; i < s.length(); i += w) {
      String line = s.substring(i, Math.min(i+w, s.length()));
      text(line, x, y);
      rows += fontSize * lineWidth;
      cols = Math.max(cols, Math.round(textWidth(line))); 
    }
    return new int[]{
      Math.round(rows),
      cols
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
    fullname = username + '@' + hostname;
    int a = 0;
    for (int i = 0; i < fullname.length(); i++) {
      a += fullname.charAt(i) * i;
    }
    userColor = colors[a % colors.length];
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
    int[] ret, tmp;
    ret = author.display(x, y, w);
    x+=ret[0];
    tmp = display(x, y, w, content, textColor, regular);
    ret[0] += tmp[0];
    ret[1] = Math.max(ret[1], tmp[1]);
    return ret;
  }
}
