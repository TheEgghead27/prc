PRCServer instance;

void setup() {
  size(1200,800);
  initScreen();

  int port = 2510;
  Server server = null;
  while (port < 65535) {
    try {
      server = new Server(this, port);
      if (server.active()) break;
    }
    catch (Exception e) {
      port++;
    }
  }
  if (server == null) exit();
  instance = new PRCServer(server);
  instance.sysPrint("PRC Server running on port " + port);
}
