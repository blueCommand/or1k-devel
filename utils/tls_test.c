static __thread int fstat ;

static __thread int fstat = 1;

static __thread int fstat ;

extern __thread int external __attribute__ ((tls_model ("initial-exec")));

int test_code(int b)
{
  fstat += b ;
  return fstat;
}

int main (int ac, char *av[])
{
  int a = test_code(1);
  
  if ( a != 2 || fstat != 2 ) return 1;

  external += 1;

  return 0;
}
