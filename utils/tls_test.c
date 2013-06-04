
extern __thread int external __attribute__ ((tls_model ("global-dynamic")));

int main (int ac, char *av[])
{
  external += ac;

  printf("Hej hej: %d\n", external);

  return 0;
}
