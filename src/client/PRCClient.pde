void clientEvent(Client client) {
  ArrayList<byte[]> packets = getPackets(client.readBytes());
  for (byte[] packet: packets)
    instance.handleServerPacket(packet);
}

public class PRCClient extends Instance {  // "PRC Client"
  Client netClient;
  User session;
  String curChannel;

  private boolean ready = false;
  ArrayList<String> sent = new ArrayList<String>();
  public PRCClient(Client c) {
    super();
    super.addCommand(new Nick());
    super.addCommand(new ClientQuit());
    Join j = new Join();
    super.addCommand(j);
    netClient = c;
    registerUser();
    j.execute(new String[]{"", "general"});
  }
  private void registerUser() {
    registerUser("");
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
    message.put("Channel", curChannel);
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
    sysPrint("GOT PACKET: " + command);
    if (command.equals("SEND")) {
      // Channel channel = channels.get(getChannel(parsed.get("Channel")));
      Message message = new Message(new User(parsed.get("User"), parsed.get("Host")), parsed.get("Content"));
      messageDisp.addLine(message);
    }

    else if (command.equals("NAME")) {
      if (parsed.get("Ours") != null) {
        session = new User(parsed.getOrDefault("User", "404"), parsed.getOrDefault("Host", "0"));
        ready = true;
      }
    }
    else if (command.equals("CHAN")) {
      while (channels.size() > 0) {
        channelDisp.removeLine(channels.remove(0));
      }
      String[] channelNames = parsed.get("Channels").split("#");
      for (String c: channelNames) {
        if (c.length() < 1) continue;
        Channel newChan = new Channel(c);
        channels.add(newChan);
        channelDisp.addLine(newChan);
      }
    }
    else if (command.equals("ERROR")) {
      sysPrint("ERROR: " + parsed.get("Error"));
    }
  }
  public boolean executeCallback() {
    if (super.executeCallback()) return true;  // early exit if command was sent
    if (!ready) {
      sysPrint("No username registration detected; are we connected to the server?");
      return false;
    }
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
      registerUser(constrainString(args[1], 10));
    }
  }
  public class ClientQuit extends Quit {
    void execute(String[] args) {
      netClient.stop();  // boy do I wish this were in an interface
      exit();
    }
  }
  public class Join implements Command {
    public String getName() {
      return "join";
    }
    public String getHelp() {
      return "Joins a channel, or creates it if there is not one. Channel names may not exceed 10 characters.";
    }
    public void execute(String[] args) {
      if (args.length < 2 || args[1].length() < 1) {
        sysPrint("`/join`: Please provide a channel name (up to 10 characters long).");
        return;
      }
      HashMap<String, String> packet = new HashMap<String, String>();
      packet.put("Command", "JOIN");
      
      String c = (args[1].startsWith("#")) ? args[1].substring(1) : args[1];
      packet.put("Channel", constrainString(c, 10));
      appendUUID(packet);
      netClient.write(encodePacket(packet));
      sysPrint("SENT JOIN #" + c);
      curChannel = c;
      channelLabel.clear();
      channelLabel.addLine(new Channel(curChannel));
    }
  }
}
