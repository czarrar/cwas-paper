double add_things(double *a, double *b, double *c, int n) {
  register double result;
  register int i;

  for (i = 0; i < n; ++i)
  {
    result += *a++ + *b++ + *c++;
  }
  return result;
}

def f():
	n = 1000000
	a = np.random.randn(1000000)
	b = np.random.randn(1000000)
	c = np.random.randn(1000000)
	for i in range(100):
	    result = (a + b + c).sum()

import numexpr as ne

def g():
	n = 1000000
	a = np.random.randn(1000000)
	b = np.random.randn(1000000)
	c = np.random.randn(1000000)
	for i in range(100):
	    result = ne.evaluate('sum(a + b + c)')

from pandas._sandbox import cython_test

def h():
    n = 1000000
    a = np.random.randn(1000000)
    b = np.random.randn(1000000)
    c = np.random.randn(1000000)
    for i in range(100):
        result = cython_test(a, b, c)
