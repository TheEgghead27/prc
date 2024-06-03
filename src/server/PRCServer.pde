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
    // parsed.put("Host", session.ip());
    server.write(super.encodePacket(parsed));
    println("DEBUG: " + super.encodePacket(parsed));
  }
}
