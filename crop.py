import numpy
import scipy.misc
import sys
import os

if len(sys.argv) != 7:
    print "python crop.py <filename> <left> <right> <top> <bottom>  <output filename>"
    quit()

filename = sys.argv[1]
left = int(sys.argv[2])
right = int(sys.argv[3])
top = int(sys.argv[4])
bottom = int(sys.argv[5])
outputfilename = sys.argv[6]

if os.path.isfile(outputfilename):
    print "File exists."
    quit()

image = (scipy.misc.imread(filename, mode = 'RGB')).astype(numpy.uint8)

h = image.shape[0]
w = image.shape[1]
print h, w
print h - top - bottom, w - left - right

new = numpy.zeros((h - top - bottom, w - left - right, 3), numpy.uint8)

for row in range (top, h - bottom):
    for col in range(left, w - right):
       for n in range (0, 3):
           new[row - top, col - left, n] = image[row, col, n]

scipy.misc.imsave(outputfilename, new)

