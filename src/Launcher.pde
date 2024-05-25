void setup() {
  size(800,800);
  background(0);

  // initialize Text fonts and rendering settings
  Text.regular = createFont("Liberation Mono", 12);
  Text.bold = createFont("Liberation Mono Bold", 12);
  Text.italic = createFont("Liberation Mono Italic", 12);
  textAlign(LEFT, TOP);
  Text.textColor = #ffffff;

  User egg = new User("egg");
  Text[] users = new Text[]{
    egg,
    new User("jnovillo", "lisa.stuy.edu"),
    new User("lenny", "stuylinux.org"),
    new User("lenny", "chat.stuywlc.org"),
    null
  };
  users[4] = new Message(egg, "hello world");

  int y = -12;
  for (Text user: users)
    user.display(5,y+=18, 1000);
}

void draw() {

}
