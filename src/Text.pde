interface Text {
  // width in characters, assuming monospace font
  void print(int x, int y, int w);
}

class User implements Text {
  private String username;
  private String hostname = "localhost";
  private color userColor;
  private color colors[] = new color[]{
    #FFFFFF,
    #FF8800,
    #00FF00,
  };

  public User(String user) {
    username = user;
    regenerateColor();
  }
  public User(String user, String host) {
    username = user;
    hostname = host;
    regenerateColor();
  }

  void print(int x, int y, int w) {
    fill(userColor);
    String buf = username + '@' + hostname;

    for (int i = 0; i < buf.length(); i += w) {
      text(buf.substring(i, Math.min(i+w, buf.length())),x,y);
    } 
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
      return true;
    }
    return false;
  }
  private void regenerateColor() {
    int a = 0;
    for (int i = 0; i < username.length(); i++) {
      a += username.charAt(i);
    }
    userColor = colors[a % colors.length];
  }
}
