public class PRCServer extends Instance {
  Server server;

  public PRCServer(Server s) {
    server = s;
    super.addCommand(new ServerQuit());
    channelLabel.addLine(new Channel("############################################ SERVER MODE ############################################"));
  }

  public void handleClientPacket(Client session, byte[] packet) {
    HashMap<String, String> parsed;
    if (packet != null) parsed = super.parsePacket(packet);
    else {
      // default to QUIT packet
      parsed = new HashMap<String, String>();
      parsed.put("Command", "QUIT");
    }
    parsed.put("Host", session.ip());

    String command = parsed.getOrDefault("Command", "NULL");
    if (DEBUG)
      sysPrint("GOT PACKET: " + command);


    if (command.equals("SEND")) {
      for (String reqHeader: new String[]{"User", "Content", "Channel"}) {
        if (parsed.get(reqHeader) == null || parsed.get(reqHeader).length() == 0) {
          session.write(error(reqHeader + " header not specified."));
          return;
        }
      }
      broadcast(parsed);
      return;  // no need to sync()
    }

    else if (command.equals("NAME")) {
      if (parsed.getOrDefault("User", "").length() == 0)
        parsed.put("User", "Guest" + users.size());
      if (parsed.get("User").indexOf("#") != -1) {
        session.write(error("Usernames cannot have `#` in them."));
        return;
      }
      User u = new User(constrainString(parsed.get("User"), USR_LIMIT), parsed.get("Host"));
      for (int i = 0; i < users.size(); i++) {
        if (users.get(i).equals(u)) {
          userDisp.removeLine(users.remove(i));
          break;
        }
        if (users.get(i).getHostname().equals(u.getHostname()) && users.get(i).getUsername().equals(parsed.get("Old User"))) {
          userDisp.removeLine(users.remove(i));
          break;
        }
      }
      users.add(u);
      userDisp.addLine(u);
      session.write(encodePacket(parsed));
    }

    else if (command.equals("JOIN")) {
      if (parsed.get("Channel") == null || parsed.get("Channel").length() == 0) {
        session.write(error("Channel header not specified."));
        return;
      }
      String cName = constrainString(parsed.get("Channel"), CHAN_LIMIT);
      if (cName.indexOf("#") != -1) {
        session.write(error("Channel names cannot have `#` in them.")); 
        return;
      }

      if (getChannel(cName) == -1) {
        Channel chan = new Channel(cName);
        channels.add(chan);
        channelDisp.addLine(chan);
      }
    }

    else if (command.equals("CHAN") || command.equals("SYNC"));  // no-op, these are just to sync()

    else if (command.equals("QUIT")) {
      if (parsed.get("User") != null) {
        User u = new User(parsed.get("User"), session.ip());
        int i;
        if ((i = userDisp.removeLine(u)) != -1) {
          users.remove(i);
        }
      }
      session.write(encodePacket(parsed));
    }

    else {
      session.write(error("Unknown command " + command));
      return;
    }
    sync();
  }

  private String error(String e) {
    HashMap<String, String> packet = new HashMap<String, String>();
    packet.put("Command", "ERROR");
    packet.put("Error", e);
    return encodePacket(packet);
  }

  private void sync() {
    HashMap<String, String> packet = new HashMap<String, String>();
    packet.put("Command", "SYNC");
    String c = "";
    for (Channel chan: channels) {
      c += chan;
      if (DEBUG)
        sysPrint("Publishing " + chan);
    }
    packet.put("Channels", c);
    String u = "";
    for (User user: users) {
      u += user.toString() + '#';
    }
    packet.put("Users", u);
    broadcast(packet);
  }

  private void broadcast(HashMap<String, String> packet) {
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
      while (client.available() > 0) {
        byte[] packet = client.readBytesUntil('\003');
        if (packet == null) break;
        instance.handleClientPacket(client, packet);
      }
    }
  }

  public class ServerQuit extends Quit {
    void execute(String[] args) {
      HashMap<String, String> packet = new HashMap<String, String>();
      packet.put("Command", "QUIT");
      broadcast(packet);
      server.stop();  // boy do I wish this were in an interface
      exit();
    }
  }
}
