public class PRCServer extends Instance {
  Server server;
  ArrayList<User> users = new ArrayList<User>();

  public PRCServer(Server s) {
    server = s;
    super.addCommand(new ServerQuit());
    channelLabel.addLine(new Channel("## SERVER MODE ###"));
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
        sysPrint("GOT PACKET: " + command);

    parsed.put("Host", session.ip());
    if (command.equals("SEND")) {
      for (String reqHeader: new String[]{"User", "Content", "Channel"}) {
        if (parsed.get(reqHeader) == null || parsed.get(reqHeader).length() == 0) {
          session.write(error(reqHeader + " header not specified."));
          return;
        }
      }
      server.write(super.encodePacket(parsed));
    }

    else if (command.equals("NAME")) {
      if (parsed.getOrDefault("User", "").length() == 0)
        parsed.put("User", "Guest" + users.size());
      else
        println("username was "+ parsed.get("User"));
      User u = new User(constrainString(parsed.get("User"), 10), parsed.get("Host"));
      for (int i = 0; i < users.size(); i++) {
        if (users.get(i).equals(u)) {
          userDisp.removeLine(users.remove(i));
          break;
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
      if (parsed.get("Channel") == null || parsed.get("Channel").length() == 0) {
        session.write(error("Channel header not specified."));
        return;
      }
      String cName = constrainString(parsed.get("Channel"), 10);
      if (cName.indexOf("#") != -1) {
        session.write(error("Channel names cannot have `#` in them.")); 
        return;
      }

      if (getChannel(cName) == -1) {
        Channel chan = new Channel(cName);
        channels.add(chan);
        channelDisp.addLine(chan);
      }

      sendChannels();
      print("channels??");
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
      sysPrint("Publishing " + chan);
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
    if ((client = instance.server.available()) != null) {
      ArrayList<byte[]> packets = getPackets(client.readBytes());
      for (byte[] packet: packets)
        instance.handleClientPacket(client, packet);
    }
  }
  public class ServerQuit extends Quit {
    void execute(String[] args) {
      server.stop();  // boy do I wish this were in an interface
      exit();
    }
  }
}
