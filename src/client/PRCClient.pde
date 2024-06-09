void clientEvent(Client client) {
  ArrayList<byte[]> packets = getPackets(client.readBytes());
  for (byte[] packet: packets)
    instance.handleServerPacket(packet);
}

public class PRCClient extends Instance {  // "PRC Client"
  Client netClient;
  User session;
  String curChannel;
  HashMap<String, ArrayList<Message>> messages = new HashMap<String, ArrayList<Message>>();

  private boolean ready = false;
  ArrayList<String> sent = new ArrayList<String>();
  public PRCClient(Client c) {
    super();
    super.addCommand(new Nick());
    super.addCommand(new ClientQuit());
    Join j = new Join();
    super.addCommand(j);
    super.addCommand(new Switch());
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
    if (m.getContent().length() < 1) return;
    HashMap<String, String> message = new HashMap<String, String>();
    message.put("Command", "SEND");
    message.put("User", m.getAuthor().getUsername());
    message.put("Host", m.getAuthor().getHostname());
    message.put("Content", m.getContent());
    message.put("Channel", curChannel);
    send(message);
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
    if (DEBUG)
      sysPrint("GOT PACKET: " + command);
    if (command.equals("SEND")) {
      Channel channel = channels.get(getChannel(parsed.get("Channel")));
      Message message = new Message(new User(parsed.get("User"), parsed.get("Host")), parsed.get("Content"));
      ArrayList<Message> m = messages.get(channel.getName());
      if (m == null) {
        m = new ArrayList<Message>();
        messages.put(channel.getName(), m);
      }
      m.add(message);
      if (curChannel.equals(channel.getName()))
        messageDisp.addLine(message);
    }

    else if (command.equals("NAME")) {
      if (parsed.get("Ours") != null) {
        session = new User(parsed.getOrDefault("User", "404"), parsed.getOrDefault("Host", "0"));
        ready = true;
      }
    }
    else if (command.equals("SYNC")) {
      channelDisp.clear();
      String[] channelNames = parsed.getOrDefault("Channels", "").split("#");
      for (String c: channelNames) {
        if (c.length() < 1) continue;
        Channel newChan = new Channel(c);
        channels.add(newChan);
        channelDisp.addLine(newChan);
      }

      String[] userNames = parsed.getOrDefault("Users", "").split("#");
      sysPrint(parsed.getOrDefault("Users", ""));
      if (userNames.length < 1) return;
      userDisp.clear();
      for (String u: userNames) {
        if (u.length() < 3) continue;
        String[] user = u.split("@");
        User newUser = new User(user[0], user[1]);
        users.add(newUser);
        userDisp.addLine(newUser);
      }
    }
    else if (command.equals("QUIT")) {
      netClient.stop();
      exit();
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
  public void send(HashMap<String, String> packet) {
    netClient.write(encodePacket(packet));
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
      HashMap<String, String> packet = new HashMap<String, String>();
      packet.put("Command", "QUIT");
      packet.put("User", session.getUsername());
      send(packet);
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
      send(packet);
      curChannel = c;
      channelLabel.clear();
      channelLabel.addLine(new Channel(curChannel));

      messageDisp.clear();
      if (messages.get(curChannel) != null)
        for (Message m: messages.get(curChannel))
          messageDisp.addLine(m);
    }
  }
  public class Switch extends Join {
    public String getName() {
      return "switch";
    }
    public String getHelp() {
      return "Switches to the specified channel. Alias of `/join`.";
    }
  }
}
