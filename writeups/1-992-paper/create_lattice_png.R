set.seed(992)
scale0to100 <- function(z)(100*(z-min(z))/(max(z)-min(z)))
f <- function(x,y)(sqrt(7^2-(x-mean(x))^2-(y-mean(y))^2))
xy <- expand.grid(x=1:10, y=1:10)
xyz <- mutate(xy, z = scale0to100(f(x,y)))
xyzu <- mutate(xyz, u = runif(nrow(xyz), 0, 100),
               z0 = 1*u + 0*z,
               z25 = 0.75*u + 0.25*z,
               z50 = 0.5*u + 0.5*z,
               z75 = 0.25*u + 0.75*z,
               z100 = 0*u + 1*z)

library(lattice)

png(filename = 'writeups/1-992-paper/plots/z100.png', bg = 'transparent')
with(xyzu, wireframe(z100 ~ x*y, zlab = 'Z', xlab = 'X', ylab = 'Y', scales = list(arrows = FALSE), par.settings = list(axis.line = list(col = 'transparent'))))
dev.off()

png(filename = 'writeups/1-992-paper/plots/z75.png', bg = 'transparent')
with(xyzu, wireframe(z75 ~ x*y, zlab = 'Z', xlab = 'X', ylab = 'Y', scales = list(arrows = FALSE), par.settings = list(axis.line = list(col = 'transparent'))))
dev.off()

png(filename = 'writeups/1-992-paper/plots/z50.png', bg = 'transparent')
with(xyzu, wireframe(z50 ~ x*y, zlab = 'Z', xlab = 'X', ylab = 'Y', scales = list(arrows = FALSE), par.settings = list(axis.line = list(col = 'transparent'))))
dev.off()

png(filename = 'writeups/1-992-paper/plots/z25.png', bg = 'transparent')
with(xyzu, wireframe(z25 ~ x*y, zlab = 'Z', xlab = 'X', ylab = 'Y', scales = list(arrows = FALSE), par.settings = list(axis.line = list(col = 'transparent'))))
dev.off()

png(filename = 'writeups/1-992-paper/plots/z0.png', bg = 'transparent')
with(xyzu, wireframe(z0 ~ x*y, zlab = 'Z', xlab = 'X', ylab = 'Y', scales = list(arrows = FALSE), par.settings = list(axis.line = list(col = 'transparent'))))
dev.off()
