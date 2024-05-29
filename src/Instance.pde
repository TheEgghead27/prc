import processing.net.Client;
import processing.net.Server;


final boolean STRICT = false;

public class Instance {
  Client client;
  Server server;
  User session;
  Input input;
  ArrayList<User> users = new ArrayList<User>();
  ArrayList<Display> screens = new ArrayList<Display>();
  ArrayList<Channel> channels = new ArrayList<Channel>();
  ArrayList<String> sent = new ArrayList<String>();
  public Instance(Client c) {
    client = c;
  }
  public Instance(Server s) {
    server = s;
  }
  public Instance(Server s, Client c) {
    client = c;
    server = s;
  }
  public boolean isClient() {
    return client != null;
  }
  public boolean isServer() {
    return server != null;
  }
  public void handleConnect(Client session) {
    // only one session allowed per ip
    if (STRICT)
      for (User u: users) {
        if (session.ip().equals(u.getHostname()))
          server.disconnect(session);
      }
  }

  public void sendMessage(Message m) {
    HashMap<String, String> message = new HashMap<String, String>();
    String uuid = "" + Math.random();
    message.put("Command", "SEND");
    message.put("User", m.getAuthor().getUsername());
    message.put("Host", m.getAuthor().getHostname());
    message.put("Content", m.getContent());
    message.put("UUID", uuid);
    client.write(encodePacket(message));
    sent.add(uuid);
  }
  public void handleServerPacket(byte[] packet) {
    HashMap<String, String> parsed = parsePacket(packet);

    // skip packets we sent
    String uuid = parsed.getOrDefault("UUID", "");
    for (int i = 0; i < sent.size(); i++) {
      if (sent.get(i).equals(uuid)) {
        sent.remove(i);
        return;
      }
    }

    String command = parsed.getOrDefault("Command", "");
    if (command.equals("SEND")) {
      // Channel channel = channels.get(getChannel(parsed.get("Channel")));
      Message message = new Message(new User(parsed.get("User"), parsed.get("Host")), parsed.get("Content"));
      screens.get(1).addLine(message);
    }
  }
  public void handleClientPacket(Client session, byte[] packet) {
    // as of right now, all packets are passed right back to clients with minimal validation (this is a bad idea)
    HashMap<String, String> parsed = parsePacket(packet);
    // parsed.put("Host", session.ip());
    server.write(encodePacket(parsed));
    println("DEBUG: " + encodePacket(parsed));
  }
  /*
   * Packet structure:
   * Command\037SEND\036Data\037Name2\036..
   * \037 (unit separator) character in place of `:`
   * \036 (record separator) character in place of '\n' or ',;
   * command: first row, identifies packet type
   *   additional fields depend on which command
   * uuid: per-transaction identifier
   * all transactions MUST end with \003
   */
  private HashMap<String, String> parsePacket(byte[] packet) {
     HashMap<String, String> buf = new HashMap<String, String>();  // totally could be a parallel array instead
     String name = "";
     String value = "";
     int index = 0;
     boolean isValue = false;

     while (index < packet.length && index >= 0) {
       String newChar = "";
       switch(packet[index]) {
         case '\n':
         case '\r':
         case '\b':
           newChar = " ";
           break;
         case '\t':
           newChar = "    ";
           break;
         case '\003':
           index = -2;
           /* fallthrough */
         case '\036':
           if (!isValue)
             println("Malformed row :(");
           buf.put(name, value);
           name = "";
           value = "";
           isValue = false;
           break;
         case '\037':
           if (isValue)
             println("Malformed row :(");
           isValue = true;
           break;
         default:
           if (packet[index] <= '\037' || packet[index] >= '\177') break;  // non-printable ASCII is discarded
           newChar += (char)packet[index];
       }
       if (newChar.length() > 0) {
         if (isValue)
           value += newChar;
         else
           name += newChar;
       }
       index++;
     }
     if (index == packet.length)
       println("Packet not terminated correctly :(");
     return buf;
  }
  private String encodePacket(HashMap<String, String> src) {
    String buf = "";
    int row = 0;
    for (String rowKey : src.keySet()) {
      buf += rowKey + '\037' + src.get(rowKey);
      if (++row == src.size())  // end of transmission
        buf += '\003';
      else
        buf += '\036';
    }
    return buf;
  }
  public void addScreen(Display screen) {
    screens.add(screen);
  }
  public void addChannel(Channel channel) {
    channels.add(channel);
  }
  private int getChannel(String channelName) {
    for (int i = 0; i < channels.size(); i++) {
      if (channels.get(i).getName().equals(channelName))
        return i;
    }
    return -1;
  }
  public boolean removeChannel(String channelName) {
    int i;
    if ((i = getChannel(channelName)) > -1) {
      channels.remove(i);
      return true;
    }
    return false;
  }
}
