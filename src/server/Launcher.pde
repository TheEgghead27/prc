Instance instance;

void setup() {
  size(1200,800);
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
  User[] users = new User[]{
    egg,
    novillo,
    lenny,
    new User("lenny", "chat.stuywlc.org"),
  };
  Message[] messages = new Message[]{
    /*
    new Message(egg, "hello world"),
    new Message(novillo, "hello friends :)"),
    new Message(lenny, "yap yap yap yap yap yap yap yap yap yap yap yap linux :P"),
    new Message(egg, "I'd just like to interject for a moment. What you're refering to as Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU plus Linux. Linux is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX. Many computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called Linux, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project. There really is a Linux, and these people are using it, but it is just a part of the system they use. Linux is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. Linux is normally used in combination with the GNU operating system: the whole system is basically GNU with Linux added, or GNU/Linux. All the so-called Linux distributions are really distributions of GNU/Linux!"),
    */
  };
  Channel[] channels = new Channel[] {
    new Channel("apcsa", "chatroom for APCSA students"),
    new Channel("dojo", "chatroom for all StuyCS students")
  };
  Display messageBox = new Display(200,0, 80, 58);
  Display[] displays = new Display[]{
    new Display(0, 0, 20, 60),
    messageBox,
    new Display(500,0, 30, 60),
    new Display(160, 700, 80, 1)
  };
  for (Text channel: channels) {
    displays[0].addLine(channel);
  }
  for (Text message: messages) {
    displays[1].addLine(message);
  }
  for(Text user: users) {
    displays[2].addLine(user);
  }
  instance = new Instance(new Server(this, 2510), new Client(this, "127.0.0.1", 2510));
  instance.input = new Input();
  displays[3].addLine(instance.input);
  float[] buf = null;
  for (Display display: displays) {
    if (buf != null) {
      if (display != displays[3])
        display.reposition((int)buf[0], 0);

    }
    buf = display.display();
    instance.screens.add(display);
    if (display == messageBox) {
      displays[3].reposition(messageBox.getX(), (int) buf[1]);
    }
  }
}

void draw() {
  if (instance.isServer()) {
    Client client;
    if ((client = instance.server.available()) != null) {
      instance.handleClientPacket(client, client.readBytes());
    }
  }
}

/*
void serverEvent(Server server, Client client) {
  if (!instance.isServer()) return;
  instance.handleClientPacket(client, client.readBytes());
}
*/
