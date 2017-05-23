import time
import numpy as np
from scipy import __version__

np.random.seed(12)

starttime = time.time()
n = 8000
A = np.matrix(np.random.rand(n,n))
B = np.matrix(np.random.rand(n,n))
print A * B
print "Elapsed seconds:", time.time()-starttime
print "numpy version", np.version.version, "scipy version", __version__

