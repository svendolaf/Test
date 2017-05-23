import time
import numpy as np
from scipy.sparse import dia_matrix
from scipy.sparse.linalg import cg
from scipy.sparse import identity
from scipy import __version__

n = 400000
diagonals = np.ones((5,n)) * -1
diagonals[2] = 4.0
offsets = (-100, -1, 0, 1, 100)
matrix = dia_matrix((diagonals, offsets), shape=(n, n))
rhs = np.ones(n)

x0 = np.zeros(n)
M = identity(n)
start = time.time()

print "Solving..."
solution, info = cg(matrix, rhs, x0=x0, tol=1e-06, maxiter= 10000,xtype=None,M=M)
print "Solve time"
print(time.time() - start)
print "Solution mean, info"
print solution.mean(), info
print "numpy version", np.version.version, "scipy version", __version__

