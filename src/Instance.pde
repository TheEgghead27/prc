import processing.net.Client;
import processing.net.Server;

final boolean STRICT = false;

public class Instance {
  Client client;
  Server server;
  User session;
  ArrayList<User> users = new ArrayList<User>();
  ArrayList<Display> screens = new ArrayList<Display>();
  ArrayList<Channel> channels = new ArrayList<Channel>();
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
  /*
   * Packet structure:
   * Name\x1FData\x1EName2..
   * \x1F (unit separator) character in place of `:`
   * \x1E (record separator) character in place of '\n' or ',;
   * command: first row, identifies packet type
   *   additional fields depend on which command
   * uuid: per-transaction identifier
   * all transactions MUST end with \x03
   */
  public void handleServerPacket(byte[] packet) {
  }
  public void handleClientPacket(Client session, byte[] packet) {
  }
  private JsonObject parsePacket(byte[] packet) {
     JsonObjectBuilder buf = new Json.createObjectBuilder();
     String name = "";
     String value = "";
     int index = 0;
     boolean isValue = false;

     while ((index < packet.length) && (packet[index] != '\x03')) {
       if (packet[index] == '\x1F') {
         if (isValue)
           println("Malformed row :(");
         isValue = true;
       }
       else if (packet[index] == '\x1E') {
         if (!isValue)
           println("Malformed row :(");
         buf.add(name, value);
         isValue = false;
         name = "";
         value = "";
       }
       else {
         if (!isValue)
           name += packet[index];
         else
           value += packet[index];
       }
     }
     if (index == packet.length)
       println("Packet not terminated correctly :(");
     return buf.build();
  }
  public void addScreen(Display screen) {
    screens.add(screen);
  }
  public void addChannel(Channel channel) {
    channels.add(channel);
  }
  public boolean removeChannel(String channelName) {
    for (int i = 0; i < channels.size(); i++) {
      if (channels.get(i).getName().equals(channelName)) {
        channels.remove(i);
        return true;
      }
    }
    return false;
  }
}
