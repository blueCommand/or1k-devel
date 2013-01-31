int main (int argc, char *argv[])
{
  static __thread int ff __attribute__ ((tls_model ("initial-exec"))) = 1234;
  ff += argc;
  return ff;
}

