PRCClient instance;

void setup() {
  size(1200,800);
  initScreen();

  instance = new PRCClient(new Client(this, "127.0.0.1", 2510));
}
