void setup() {
  size(800,800);
  background(0);

  // initialize Text fonts and rendering settings
  Text.lineSpace = .5;
  Text.fontSize = 12;
  Text.regular = createFont("Liberation Mono", Text.fontSize);
  Text.bold = createFont("Liberation Mono Bold", Text.fontSize);
  Text.italic = createFont("Liberation Mono Italic", Text.fontSize);
  textAlign(LEFT, TOP);
  Text.textColor = #ffffff;
  textFont(Text.regular);
  Text.fontWidth = textWidth(" ");  // monospace font means we can assume this is uniform

  User egg = new User("egg");
  User novillo = new User("jnovillo", "lisa.stuy.edu");
  User lenny = new User("lenny", "stuylinux.org");
  Text[] texts = new Text[]{
    egg,
    novillo,
    lenny,
    new User("lenny", "chat.stuywlc.org"),
    new Message(egg, "hello world"),
    new Message(novillo, "hello friends :)"),
    new Message(lenny, "yap yap yap yap yap yap yap yap yap yap yap yap :P")
  };

  int y = 6;
  for (Text text: texts) {
    y += ((text.display(5, y, 20))[0] + Text.lineSpace) * Text.fontSize;
  }
}

void draw() {

}
