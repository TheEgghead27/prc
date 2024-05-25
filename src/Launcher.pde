void setup() {
  size(800,800);
  background(0);
  Text.regular = createFont("Liberation Mono", 12);
  Text.bold = createFont("Liberation Mono Bold", 12);
  Text.italic = createFont("Liberation Mono Italic", 12);
  textFont(Text.italic);

  textAlign(LEFT, TOP);
  Text[] users = new Text[]{
    new User("egg"),
    new User("jnovillo", "lisa.stuy.edu"),
    new User("lenny", "stuylinux.org"),
    new User("lenny", "chat.stuywlc.org")
  };
  int y = -12;
  for (Text user: users)
    user.print(5,y+=18, 1000);
}

void draw() {

}
