void setup() {
  size(800,800);
  background(255);
  // TODO: monospace font
  textAlign(LEFT, TOP);
  Text[] users = new Text[]{
    new User("egg"),
    new User("jnovillo", "lisa.stuy.edu"),
    new User("lenny", "stuylinux.org"),
    new User("lenny", "chat.stuywlc.org")
  };
  int y = -25;
  for (Text user: users)
    user.print(5,y+=30, 1000);
}

void draw() {

}
