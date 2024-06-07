public class PRCClient extends Instance {  // "PRC Client"
  Client netClient;
  User session;
  ArrayList<String> sent = new ArrayList<String>();
  public PRCClient(Client c) {
    super();
    netClient = c;
  }
  public void sendMessage(Message m) {
    HashMap<String, String> message = new HashMap<String, String>();
    String uuid = "" + Math.random();
    message.put("Command", "SEND");
    message.put("User", m.getAuthor().getUsername());
    message.put("Host", m.getAuthor().getHostname());
    message.put("Content", m.getContent());
    message.put("UUID", uuid);
    netClient.write(super.encodePacket(message));
    sent.add(uuid);
    instance.screens.get(1).addLine(m);
    screens.get(1).display();
    println("hrm rhm");
  }

  public void handleServerPacket(byte[] packet) {
    HashMap<String, String> parsed = super.parsePacket(packet);

    // skip packets we sent
    String uuid = parsed.getOrDefault("UUID", "");
    for (int i = 0; i < sent.size(); i++) {
      if (sent.get(i).equals(uuid)) {
        sent.remove(i);
        println("short circuitng");
        return;
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
  }
  public boolean executeCallback() {
    if (super.executeCallback()) return true;  // early exit if command was sent
    Message m = new Message(new User(userNameTmp, "127.0.0.1"), getInput());
    sendMessage(m);
    setInput("");
    return true;
  }
}
