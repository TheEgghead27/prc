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

  int[] display(int x1, int y1, int x2, int y2, int w, String s, color c, PFont font) {
    textFont(font);
    return display(x1, y1, x2, y2, w, s, c);
  }
  int[] display(int x1, int y1, int x2, int y2, int w, String s, color c) {
    fill(c);
    return display(x1, y1, x2, y2, w, s);
  }
  int[] display(int x1, int y1, int x2, int y2, int w, String s) {
    int rows = 0;  // number of character rows
    int remain = 0;  // number of characters printed in last row

    for (int i = 0; i < s.length(); i += w) {
      String line = s.substring(i, Math.min(i+w, s.length()));
      text(line, x1, y1 + rows * fontSize, x2 - x1, y2 - y1);
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
}

class Channel extends Text {
  private String name;
  private String topic;
  public Channel(String n) {
    name = n;
    topic = "";
  }
  public Channel(String n, String t) {
    name = n;
    topic = t;
  }

  String getName() {
    return name;
  }
  String getTopic() {
    return topic;
  }
  boolean setTopic(String newTopic) {
    if (newTopic.length() > 0) {
      topic = newTopic;
      return true;
    }
    return false;
  }
  int[] display(int x1, int y1, int x2, int y2, int w) {
    String disp = "#" + name;
    return display(x1, y1, x2, y2, w, disp, textColor, bold);
  }
  int[] displayVerbose(int x1, int y1, int x2, int y2, int w) {
    int[] ret = display(x1, y1, x2, y2, w);
    int[] tmp;
    y1 += ret[0] * fontSize;
    tmp = display(x1, y1, x2, y2, w, topic, textColor, regular);
    ret[0] += tmp[0];
    ret[1] = tmp[1];
    return ret;
  }
}
