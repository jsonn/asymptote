import three;

//size(10cm);

currentprojection=perspective(40,40,50);

// Nonrational surface:
// udegree=3, vdegree=3, nu=5, nv=6;
real[] uknot={0,0,0,0,0.5,1,1,1,1};
real[] vknot={0,0,0,0,0.4,0.6,1,1,1,1};

triple[][] P={{
  (-31.2061,12.001,6.45082),
  (-31.3952,14.7353,6.53707),
  (-31.5909,21.277,6.70051),
  (-31.4284,25.4933,6.76745),
  (-31.5413,30.3485,6.68777),
  (-31.4896,32.2839,6.58385),
  },{
  (-28.279,12.001,7.89625),
  (-28.4187,14.7353,8.00954),
  (-28.5633,21.277,8.22422),
  (-28.4433,25.4933,8.31214),
  (-28.5266,30.3485,8.20749),
  (-28.4885,32.2839,8.07099),
  },{
  (-20,12.001,10.0379),
  (-20,14.7353,10.2001),
  (-20,21.277,10.5076),
  (-20,25.4933,10.6335),
  (-20,30.3485,10.4836),
  (-20,32.2839,10.2881),
  },{
  (-11.721,12.001,7.84024),
  (-11.5813,14.7353,7.95269),
  (-11.4367,21.277,8.16575),
  (-11.5567,25.4933,8.25302),
  (-11.4734,30.3485,8.14915),
  (-11.5115,32.2839,8.01367),
  },{
  (-8.79391,12.001,6.39481),
  (-8.60483,14.7353,6.48022),
  (-8.40905,21.277,6.64204),
  (-8.57158,25.4933,6.70832),
  (-8.45874,30.3485,6.62943),
  (-8.51041,32.2839,6.52653)
  }};

draw(P,uknot,vknot,new pen[] {red,green,blue,magenta});

// Rational Bezier patch:
// udegree=3, vdegree=3, nu=4, nv=4;
real[] uknot={0,0,0,0,1,1,1,1};
real[] vknot={0,0,0,0,1,1,1,1};
triple[][] P=scale3(20)*octant1.P;

// Optional weights:
real[][] weights=array(P.length,array(P[0].length,1.0));
weights[1][2]=0.5;

draw(P,uknot,vknot,weights,blue);
