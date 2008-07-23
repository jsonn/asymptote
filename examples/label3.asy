import surface;

settings.outformat="pdf";
size(100);

currentprojection=perspective(100,100,100,up=Y);

label("$\displaystyle\int_{-\infty}^{+\infty} e^{-\alpha x^2}\,dx=
\sqrt{\frac{\pi}{\alpha}}$",O,blue);
