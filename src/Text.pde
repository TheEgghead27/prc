interface Text {
  // width in characters, assuming monospace font
  void print(int x, int y, int w);
}

color colors[] = new color[]{
    #FF8800,
    #FF2222,
    #00FF00,
    #00FF88,
    #0088FF,
    #FF00FF
};

class User implements Text {
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
    fill(userColor);

    for (int i = 0; i < fullname.length(); i += w) {
      text(fullname.substring(i, Math.min(i+w, fullname.length())),x,y);
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
