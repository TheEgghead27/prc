import processing.net.Client;
import processing.net.Server;
import java.util.Arrays;

final boolean DEBUG = false;

void draw() {
  instance.draw();
}

void keyPressed() {
  if (keyCode == 38 || keyCode == 40) {
    // up and down are 38 and 40 respectively
    instance.messageDisp.addOffset(keyCode - 39);
  }
  else if (keyCode == '\177' || keyCode == '\b')
    instance.setInput(instance.getInput().substring(0, Math.max(instance.getInput().length() - 1, 0)));
  else if (keyCode == '\n' || keyCode == '\r') {
    instance.executeCallback();
  }
  else if (key < ' ' || key >= '\177')  // non-printable ASCII
    return;
  else
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

  private static final int WINDOW_PADDING = 50;
  static final int CHAN_LIMIT = 18;
  static final int USR_LIMIT = 16;

  private User SYSUSER = new User("***SYSTEM***", null);

  public Instance() {
    commands.add(new Help());

    screens.add(channelDisp = new Display(WINDOW_PADDING, WINDOW_PADDING, 20, 60));
    screens.add(channelLabel = new Display(0, 0, 100, 1));
    screens.add(messageDisp = new Display(0, 0, 100, 56));
    screens.add(inputDisp = new Display(0, 0, 100, 1));
    inputDisp.addLine(input);
    screens.add(userDisp = new Display(0, 0, 30, 60));

    float[] buf = null;
    for (Display display: screens) {
      if (buf != null) {
        if (display == messageDisp || display == inputDisp) {
          display.reposition(channelLabel.getX(), (int)buf[1]);
        }
        else {
          display.reposition((int)buf[0], WINDOW_PADDING);
        }
      }
      buf = display.display();
    }
    if (buf != null)
      windowResize((int) buf[0] + WINDOW_PADDING, (int) buf[1] + WINDOW_PADDING);
    else
      sysPrint("Failed to resize window, did a display break?");
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

  public int getChannel(String channelName) {
    for (int i = 0; i < channels.size(); i++) {
      if (channels.get(i).getName().equals(channelName))
        return i;
    }
    return -1;
  }

  public void addScreen(Display screen) {
    screens.add(screen);
  }

  public void refresh() {
    for (Display s: screens)
      s.markRerender();
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
      for (Command c: commands) {
        sysPrint("/" + c.getName() + ": " + c.getHelp());
      }
    }
  }
}
