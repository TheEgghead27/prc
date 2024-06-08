PRCServer instance;

void setup() {
  size(1200,800);
  initScreen();

  instance = new PRCServer(new Server(this, 2510));
}
