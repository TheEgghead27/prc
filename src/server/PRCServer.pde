void serverEvent(Server server, Client client) {
  instance.handleClientPacket(client, client.readBytes());
}


public class PRCServer extends Instance {
  Server server;
  ArrayList<User> users = new ArrayList<User>();

  public PRCServer(Server s) {
    server = s;
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
    println("packet" + parsed.get("Command"));
    
    String command = parsed.getOrDefault("Command", "UNDEF");
    if (command.equals("SEND"))
      server.write(super.encodePacket(parsed));
    else if (command.equals("NAME")) {
      if (parsed.get("User") == null)
        parsed.put("User", "Guest" + users.size());
      parsed.put("Host", session.ip());
      User u = new User(parsed.get("User"), parsed.get("Host"));
      for (int i = 0; i < users.size(); i++) {
        if (users.get(i).equals(u)) {
          if (!parsed.get("Old User").equals(""))
            return;  // we can skip
          else {
            userDisp.removeLine(users.remove(i));
            break;
          }
        }
        if (users.get(i).getHostname() == parsed.get("User") && users.get(i).getUsername() == parsed.get("Old User")) {
          userDisp.removeLine(users.remove(i));
          break;
        }
      }
      users.add(u);
      userDisp.addLine(u);
      session.write(super.encodePacket(parsed));
      println("registered user " + users.get(users.size() - 1));
    }
    else if (command.equals("QUIT")) {
      for (int i = 0; i < users.size(); i++) {
        if (users.get(i).getHostname().equals(session.ip())) {
          userDisp.removeLine(users.remove(i));
          break;
        }
      }
    }
    else {
      sysPrint("Unknown command " + command);
    }
    // println("DEBUG: " + super.encodePacket(parsed));
  }
  public boolean executeCallback() {
    if (super.executeCallback()) return true;
    sysPrint("Unrecognized command `" + getInput() + "`.");
    sysPrint("Type `/help` for information.");
    setInput("");
    return true;
  }
  public void draw() {
    super.draw();
    Client client;
    if ((client = instance.server.available()) != null)
      instance.handleClientPacket(client, client.readBytes());
  }
}
