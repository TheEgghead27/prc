void clientEvent(Client client) {
  while (client.available() > 0) {
    byte[] packet = client.readBytesUntil('\003');
    if (packet == null) break;
    instance.handleServerPacket(packet);
  }
}

public class PRCClient extends Instance {  // "PRC Client"
  private PApplet handle;  // to be used in initializing Client()
  private Client netClient;

  private User session;
  private ArrayList<String> sent = new ArrayList<String>();
  private boolean ready = false;

  private String curChannel;
  private HashMap<String, ArrayList<Message>> messages = new HashMap<String, ArrayList<Message>>();

  public PRCClient(PApplet handle) {
    super();
    super.addCommand(new Nick());
    super.addCommand(new ClientQuit());
    super.addCommand(new Join());
    super.addCommand(new Switch());
    this.handle = handle;
    sysPrint("Please enter the IP address of the PRC server you wish to connect to.");
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

    // mark packets that are responses to ones we sent
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
    // initial state - trying to connect to given server IP
    if (netClient == null || !netClient.active()) {
      String[] serverInfo = getInput().split(":");
      int port = 2510;
      if (serverInfo.length > 1) {
        try {
          port = Integer.valueOf(serverInfo[1]);
        }
        catch (NumberFormatException e) {
          sysPrint("Failed to parse port \"" + serverInfo[1] + "\", defaulting to 2510"); 
        }
      }
      sysPrint("Connecting to " + serverInfo[0] + " on port " + port + "...");
      netClient = new Client(handle, serverInfo[0], port);
      if (netClient.active()) {
        setInput("");
        sysPrint("Successfully connected.");
        registerUser();
        (new Join()).execute(new String[]{"", "general"});
      }
      else {
        sysPrint("Connection failed. Please enter the server IP address again.");
        netClient = null;
      }
      return true;
    }

    // managed to connect to the server, but still may have session = null or other uninitialized states
    if (!ready) {
      sysPrint("No username registration detected; are we connected to the server?");
      return false;
    }

    if (super.executeCallback()) return true;  // early exit if a command was run

    // read and send message
    Message m = new Message(session, getInput());
    sendMessage(m);
    setInput("");
    return true;
  }

  private void send(HashMap<String, String> packet) {
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
      registerUser(args[1]);
    }
  }

  public class ClientQuit extends Quit {
    void execute(String[] args) {
      HashMap<String, String> packet = new HashMap<String, String>();
      packet.put("Command", "QUIT");
      if (session != null)
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
      
      curChannel = constrainString((args[1].startsWith("#")) ? args[1].substring(1) : args[1], CHAN_LIMIT);
      packet.put("Channel", curChannel);
      appendUUID(packet);
      send(packet);
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
