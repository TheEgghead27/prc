static abstract class TextConstants {
  static PFont regular, bold, italic;
}
abstract class Text extends TextConstants {
  // width in characters, assuming monospace font
  abstract void print(int x, int y, int w);

  void print(int x, int y, int w, String s, color c, PFont font) {
    textFont(font);
    print(x,y,w,s,c);
  }
  void print(int x, int y, int w, String s, color c) {
    fill(c);
  }
  void print(int x, int y, int w, String s) {
    for (int i = 0; i < s.length(); i += w) {
      text(s.substring(i, Math.min(i+w, s.length())),x,y);
    }
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

  void print(int x, int y, int w) {
    super.print(x,y,w,fullname,userColor,bold);
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
