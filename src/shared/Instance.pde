import processing.net.Client;
import processing.net.Server;

final boolean STRICT = false;

public void initScreen() {
  background(0);

  // initialize Text fonts and rendering settings
  Text.lineSpace = .5;
  Text.fontSize = 12;
  Text.regular = createFont("Liberation Mono", Text.fontSize);
  Text.bold = createFont("Liberation Mono Bold", Text.fontSize);
  Text.italic = createFont("Liberation Mono Italic", Text.fontSize);
  textAlign(LEFT, TOP);
  Text.textColor = #ffffff;
  textFont(Text.regular);
  Text.fontWidth = textWidth(" ");  // monospace font means we can assume this is uniform
}

public class Instance {
  Input input;
  ArrayList<Display> screens = new ArrayList<Display>();
  ArrayList<Channel> channels = new ArrayList<Channel>();
 //<>//
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
