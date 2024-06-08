import processing.net.Client;
import processing.net.Server;
import java.util.Arrays;

final boolean STRICT = false;
final boolean DEBUG = true;

void draw() {
  instance.draw();
}

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

void keyPressed() {
  if (keyCode == '\177' || keyCode == '\b')
    instance.setInput(instance.getInput().substring(0, Math.max(instance.getInput().length() - 1, 0)));
  if (keyCode == '\n' || keyCode == '\r') {
    instance.executeCallback();
  }
  instance.screens.get(3).markRerender();
  if (key < ' ' || key >= '\177')  // non-printable ASCII
    return;
  instance.setInput(instance.getInput() + key);
}

interface Command {
  public abstract String getName();
  public abstract String getHelp();
  public abstract void execute(String[] args);
}

public static String constrainString(String s, int l) {
  return (s.length() > l ? s.substring(0,l) : s);
}

public static ArrayList<byte[]> getPackets(byte[] queue){
  ArrayList<byte[]> packets = new ArrayList<byte[]>(1);
  int prev = 0;
  for (int i = 0; i < queue.length; i++) {
    if (queue[i] == '\003') {
      packets.add(Arrays.copyOfRange(queue, prev, prev = ++i));
    }
  }
  return packets;
}

public class Instance {
  private Input input = new Input();
  ArrayList<Display> screens = new ArrayList<Display>();
  Display inputDisp;
  Display messageDisp;
  Display channelDisp;
  Display channelLabel;
  Display userDisp;

  ArrayList<User> users = new ArrayList<User>();
  ArrayList<Channel> channels = new ArrayList<Channel>();
  ArrayList<Command> commands = new ArrayList<Command>(2);
  private User SYSUSER = new User("***SYSTEM***", null);

  public Instance() {
    commands.add(new Help());

    screens.add(channelDisp = new Display(0, 0, 20, 60));
    screens.add(channelLabel = new Display(0, 0, 80, 1));
    screens.add(messageDisp = new Display(0, 0, 80, 56));
    screens.add(inputDisp = new Display(0, 0, 80, 1));
    inputDisp.addLine(input);
    screens.add(userDisp = new Display(0, 0, 30, 60));

    float[] buf = null;
    for (Display display: screens) {
      if (buf != null) {
        if (display == messageDisp || display == inputDisp) {
          display.reposition(channelLabel.getX(), (int)buf[1]);
        }
        else {
          display.reposition((int)buf[0], 0);
        }
      }
      buf = display.display();
    }
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
             sysPrint("Parse error: Malformed row :(");
           buf.put(name, value);
           name = "";
           value = "";
           isValue = false;
           break;
         case '\037':
           if (isValue)
             sysPrint("Parse error: Malformed row :(");
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
       sysPrint("Parse error: Packet not terminated correctly :(");
     return buf;
  }
  public String encodePacket(HashMap<String, String> src) {
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
  public int getChannel(String channelName) {
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
  public String getInput() {
    return input.content;
  }
  public void setInput(String newInput) {
    input.content = newInput;
    inputDisp.markRerender();
  }
  public boolean executeCallback() {
    if (input.content.startsWith("/")) {
      String[] args = input.content.substring(1).split(" ");
      if (args.length == 0) return false;
      boolean executed = false;
      for (Command c: commands) {
        if (args[0].equals(c.getName())) {
          c.execute(args);
          executed = true;
          break;
        }
      }
      if (!executed) {
        printUnknown();
      }
      setInput("");
      return true;
    }
    return false;
  }
  public void printUnknown() {
    sysPrint("Unrecognized command `" + getInput() + "`.");
    sysPrint("Type `/help` for information.");
    setInput("");
  }
  public void sysPrint(String line) {
    messageDisp.addLine(new Message(SYSUSER, line));
    messageDisp.markRerender();
  }
  public void draw() {
    for (Display screen: screens)
      screen.display();
  }
  public void addCommand(Command c) {
    commands.add(c);
  }

  public abstract class Quit implements Command {
    public String getName() {
      return "quit";
    }
    public String getHelp() {
      return "Quits the program";
    }
    public abstract void execute(String[] args);
  }

  public class Help implements Command {
    public String getName() {
      return "help";
    }
    public String getHelp() {
      return "Shows this help text";
    }
    public void execute(String[] args) {
      sysPrint("Processing Relay Chat");
      sysPrint("Usage: /<command>");
      for (int i = commands.size() - 1; i >= 0; i--) {
        sysPrint("/" + commands.get(i).getName() + ": " + commands.get(i).getHelp());
      }
    }
  }
}
