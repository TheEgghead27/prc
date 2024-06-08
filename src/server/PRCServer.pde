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
    // as of right now, all packets are passed right back to clients with minimal validation (this is a bad idea)
    HashMap<String, String> parsed = super.parsePacket(packet);
    String command = parsed.getOrDefault("Command", "");
    if (command.equals("SEND"))
      server.write(super.encodePacket(parsed));
    else if (command.equals("NAME")) {
      if (parsed.get("User") == null)
        parsed.put("User", "Guest" + users.size());
      parsed.put("Host", session.ip());
      users.add(new User(parsed.get("User"), parsed.get("Host")));  // TODO: remove defunct sessions
      session.write(super.encodePacket(parsed));
      println("registered user " + users.get(users.size() - 1));
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
