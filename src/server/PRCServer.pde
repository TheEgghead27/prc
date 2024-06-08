public class PRCServer extends Instance {
  Server server;
  ArrayList<User> users = new ArrayList<User>();

  public PRCServer(Server s) {
    server = s;
    super.addCommand(new ServerQuit());
  }

  public void handleConnect(Client session) {
    // only one session allowed per ip
    if (STRICT)
      for (User u: users) {
        if (session.ip().equals(u.getHostname()))
          server.disconnect(session);
      }
  }

  public void handleClientPacket(Client session, byte[] packet) {
    HashMap<String, String> parsed;
    if (packet != null) parsed = super.parsePacket(packet);
    else {
       parsed = new HashMap<String, String>();
       parsed.put("Command", "QUIT");
    }


    String command = parsed.getOrDefault("Command", "UNDEF");
    if (command.equals("SEND"))
      server.write(super.encodePacket(parsed));

    else if (command.equals("NAME")) {
      if (parsed.get("User") == null)
        parsed.put("User", "Guest" + users.size());
      parsed.put("Host", session.ip());
      User u = new User(constrainString(parsed.get("User"), 10), parsed.get("Host"));
      for (int i = 0; i < users.size(); i++) {
        if (users.get(i).equals(u)) {
          if (!parsed.get("Old User").equals(""))
            return;  // we can skip
          else {
            userDisp.removeLine(users.remove(i));
            break;
          }
        }
        println(parsed.get("Old User") + "!");
        if (users.get(i).getHostname().equals(u.getHostname()) && users.get(i).getUsername().equals(parsed.get("Old User"))) {
          println("removing old user");
          userDisp.removeLine(users.remove(i));
          break;
        }
      }
      users.add(u);
      userDisp.addLine(u);
      session.write(super.encodePacket(parsed));
      println("registered user " + users.get(users.size() - 1));
    }

    else if (command.equals("JOIN")) {
      for (String reqHeader: new String[]{"User", "Channel"}) {
        if (parsed.get(reqHeader) == null || parsed.get(reqHeader).length() == 0) {
          session.write(error(reqHeader + " header not specified."));
          return;
        }
      }

      User u = new User(parsed.get("User"), session.ip());
      int index = -1;
      for (int i = 0; i < users.size(); i++) {
        if (users.get(i).equals(u)) {
          index = i;
          break;
        }
      }
      if (index == -1) {
         session.write(error("Invalid user."));
         return;
      }
      String cName = constrainString(parsed.get("Channel"), 10);
      if (cName.indexOf("#") != -1) {
        session.write(error("Channel names cannot have `#` in them.")); 
      }

      if (getChannel(cName) == -1) {
        Channel chan = new Channel(cName);
        channels.add(chan);
        channelDisp.addLine(chan);
      }

      sendChannels();
    }

    else if (command.equals("CHAN"))
      sendChannels();

    else {
      sysPrint("Unknown command " + command);
    }
  }
  private String error(String e) {
    HashMap<String, String> packet = new HashMap<String, String>();
    packet.put("Command", "ERROR");
    packet.put("Error", e);
    return super.encodePacket(packet);
  }
  private void sendChannels() {
    HashMap<String, String> packet = new HashMap<String, String>();
    packet.put("Command", "CHAN");
    String c = "";
    for (Channel chan: channels) {
      c += chan;
    }
    packet.put("Channels", c);
    server.write(encodePacket(packet));
  }
  public boolean executeCallback() {
    if (super.executeCallback()) return true;
    printUnknown();
    return true;
  }
  public void draw() {
    super.draw();
    Client client;
    if ((client = instance.server.available()) != null)
      instance.handleClientPacket(client, client.readBytes());
  }
  public class ServerQuit extends Quit {
    void execute(String[] args) {
      server.stop();  // boy do I wish this were in an interface
      exit();
    }
  }
}
