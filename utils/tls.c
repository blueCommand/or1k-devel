int main (int argc, char *argv[])
{
  static __thread int ff = 1234;
  ff += argc;
  return ff;
}

