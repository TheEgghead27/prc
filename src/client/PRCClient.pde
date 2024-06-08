public class PRCClient extends Instance {  // "PRC Client"
  Client netClient;
  User session;
  private boolean ready = false;
  ArrayList<String> sent = new ArrayList<String>();
  public PRCClient(Client c) {
    super();
    super.addCommand(new Nick());
    netClient = c;
    registerUser();
  }
  private void registerUser() {
    registerUser("Guest");
  }
  private void registerUser(String username) {
      HashMap<String, String> packet = new HashMap<String, String>();
      packet.put("Command", "NAME");
      packet.put("User", username);
      packet.put("Old User", (session == null) ? "" : session.getUsername());
      appendUUID(packet);
      netClient.write(super.encodePacket(packet));
  }
  public void sendMessage(Message m) {
    HashMap<String, String> message = new HashMap<String, String>();
    message.put("Command", "SEND");
    message.put("User", m.getAuthor().getUsername());
    message.put("Host", m.getAuthor().getHostname());
    message.put("Content", m.getContent());
    appendUUID(message);
    netClient.write(super.encodePacket(message));
  }
  private void appendUUID(HashMap<String, String> packet) {
    String uuid = "" + Math.random();
    packet.put("UUID", uuid);
    sent.add(uuid);
  }

  public void handleServerPacket(byte[] packet) {
    HashMap<String, String> parsed = super.parsePacket(packet);

    // skip packets we sent
    String uuid = parsed.getOrDefault("UUID", "");
    for (int i = 0; i < sent.size(); i++) {
      if (sent.get(i).equals(uuid)) {
        sent.remove(i);
        parsed.put("Ours", ":)");  // arbitrary non-null value
        break;
      }
    }

    String command = parsed.getOrDefault("Command", "");
    if (command.equals("SEND")) {
      // Channel channel = channels.get(getChannel(parsed.get("Channel")));
      Message message = new Message(new User(parsed.get("User"), parsed.get("Host")), parsed.get("Content"));
      instance.screens.get(1).addLine(message);
      instance.screens.get(1).display();
      println("hrmm?? " + parsed.get("Content"));
    }
    else if (command.equals("NAME")) {
      if (parsed.get("Ours") != null) {
        session = new User(parsed.getOrDefault("User", "404"), parsed.getOrDefault("Host", "0"));
        ready = true;
      }
    }
  }
  public boolean executeCallback() {
    if (super.executeCallback()) return true;  // early exit if command was sent
    if (!ready) {
      sysPrint("No username registration detected; are we connected to the server?");
      return false;
    }
    println(session);
    Message m = new Message(session, getInput());
    sendMessage(m);
    setInput("");
    return true;
  }
  public class Nick implements Command {
    public String getName() {
      return "nick";
    }
    public String getHelp() {
      return "Sets your nickname to the given string (10 characters max, no spaces)";
    }
    public void execute(String[] args) {
      if (args.length < 2 || args[1].length() < 1) {
        sysPrint("`/nick`: Please provide a nickname (up to 10 characters long).");
        return;
      }
      String username = (args[1].length() > 10 ? args[1].substring(0,10) : args[1]);
      registerUser(username);
    }
  }
}
