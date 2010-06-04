import three;
import graph3;

pen defaultbackpen=linetype(new real[] {4,4},4,scale=false);

// A solid geometry package.

// Try to find a bounding tangent line between two paths.
real[] tangent(path p, path q, bool side) 
{
  static real fuzz=1.0e-5;

  if((cyclic(p) && inside(p,point(q,0)) || 
      cyclic(q) && inside(q,point(p,0))) &&
     intersect(p,q,fuzz).length == 0) return new real[];

  for(int i=0; i < 100; ++i) {
    real ta=side ? mintimes(p)[1] : maxtimes(p)[1];
    real tb=side ? mintimes(q)[1] : maxtimes(q)[1];
    pair a=point(p,ta);
    pair b=point(q,tb);
    real angle=angle(b-a,warn=false);
    if(abs(angle) <= sqrtEpsilon || abs(abs(0.5*angle)-pi) <= sqrtEpsilon)
      return new real[] {ta,tb};
    transform t=rotate(-degrees(angle));
    p=t*p;
    q=t*q;
  }
  return new real[];
}

path line(path p, path q, real[] t) 
{
  return point(p,t[0])--point(q,t[1]);
}

// Return the projection of a generalized cylinder of height h constructed
// from area base in the XY plane and aligned with axis.
path[] cylinder(path3 base, real h, triple axis=Z,
                projection P=currentprojection) 
{
  base=rotate(-colatitude(axis),cross(axis,Z))*base;
  path3 top=shift(h*axis)*base;
  path Base=project(base,P);
  path Top=project(top,P);
  real[] t1=tangent(Base,Top,true);
  real[] t2=tangent(Base,Top,false);
  path p=subpath(Base,t1[0]/P.ninterpolate,t2[0]/P.ninterpolate);
  path q=subpath(Base,t2[0]/P.ninterpolate,t1[0]/P.ninterpolate);
  return Base^^Top^^line(Base,Top,t1)^^line(Base,Top,t2);
}

// The three-dimensional "wireframe" used to visualize a volume of revolution
struct skeleton {
  struct curve {
    path3[] front;
    path3[] back;
  }
  // transverse skeleton (perpendicular to axis of revolution)
  curve transverse;
  // longitudinal skeleton (parallel to axis of revolution)
  curve longitudinal;
}

// A surface of revolution generated by rotating a planar path3 g
// from angle1 to angle2 about c--c+axis.
struct revolution {
  triple c;
  path3 g;
  triple axis;
  real angle1,angle2;
  triple M;
  triple m;

  static real epsilon=10*sqrtEpsilon;
  
  void operator init(triple c=O, path3 g, triple axis=Z, real angle1=0,
                     real angle2=360) {
    this.c=c;
    this.g=g;
    this.axis=unit(axis);
    this.angle1=angle1;
    this.angle2=angle2;
    M=max(g);
    m=min(g);
  }
  
  // Return the surface of rotation obtain by rotating the path3 (x,0,f(x))
  // sampled n times between x=a and x=b about an axis lying in the XZ plane.
  void operator init(triple c=O, real f(real x), real a, real b, int n=ngraph,
                     interpolate3 join=operator --, triple axis=Z,
                     real angle1=0, real angle2=360) {
    operator init(c,graph(new triple(real x) {return (x,0,f(x));},a,b,n,
                          join),axis,angle1,angle2);
  }

  revolution copy() {
    return revolution(c,g,axis,angle1,angle2);
  }
  
  triple vertex(int i, real j) {
    triple v=point(g,i);
    triple center=c+dot(v-c,axis)*axis;
    triple perp=v-center;
    triple normal=cross(axis,perp);
    return center+Cos(j)*perp+Sin(j)*normal;
  }

  // Construct the surface of rotation generated by rotating g
  // from angle1 to angle2 sampled n times about the line c--c+axis.
  // An optional surface pen color(int i, real j) may be specified
  // to override the color at vertex(i,j).
  surface surface(int n=nslice, pen color(int i, real j)=null) {
    return surface(c,g,axis,n,angle1,angle2,color);
  }

  path3 slice(real position, int n=nCircle) {
    triple v=point(g,position);
    triple center=c+dot(v-c,axis)*axis;
    triple perp=v-center;
    if(abs(perp) <= epsilon*max(abs(m),abs(M))) return center;
    triple v1=center+rotate(angle1,axis)*perp;
    triple v2=center+rotate(angle2,axis)*perp;
    path3 p=Arc(center,v1,v2,axis,n);
    return (angle2-angle1) % 360 == 0 ? p&cycle : p;
  }
  
  triple camera(projection P) {
    triple camera=P.camera;
    if(P.infinity) {
      real s=abs(M-m)+abs(m-P.target);
      camera=P.target+camerafactor*s*unit(P.vector());
    }
    return camera;
  }

  // add transverse slice to skeleton s;
  // must be recomputed if camera is adjusted
  void transverse(skeleton s, real t, int n=nslice,
		  projection P=currentprojection) {
    skeleton.curve s=s.transverse;
    path3 S=slice(t,n);
    triple camera=camera(P);
    int L=length(g);
    real midtime=0.5*L;
    real sign=sgn(dot(axis,camera-P.target))*sgn(dot(axis,dir(g,midtime)));
    if(dot(M-m,axis) == 0 || (t <= epsilon && sign < 0) ||
       (t >= L-epsilon && sign > 0))
      s.front.push(S);
    else {
      path3 Sp=slice(t+epsilon,n);
      path3 Sm=slice(t-epsilon,n);
      path sp=project(Sp,P);
      path sm=project(Sm,P);
      real[] t1=tangent(sp,sm,true);
      real[] t2=tangent(sp,sm,false);
      if(t1.length > 1 && t2.length > 1) {
        real t1=t1[0]/P.ninterpolate;
        real t2=t2[0]/P.ninterpolate;
        int len=length(S);
        if(t2 < t1) {
          real temp=t1;
          t1=t2;
          t2=temp;
        }
        path3 p1=subpath(S,t1,t2);
        path3 p2=subpath(S,t2,len);
        path3 P2=subpath(S,0,t1);
        if(abs(midpoint(p1)-camera) <= abs(midpoint(p2)-camera)) {
          s.front.push(p1);
          if(cyclic(S))
            s.back.push(p2 & P2);
          else {
            s.back.push(p2);
            s.back.push(P2);
          }
        } else {
          if(cyclic(S))
            s.front.push(p2 & P2);
          else {
            s.front.push(p2);
            s.front.push(P2);
          }
          s.back.push(p1);
        }
      } else {
        if((t <= midtime && sign < 0) || (t >= midtime && sign > 0))
          s.front.push(S);
        else
          s.back.push(S);
      }
    }
  }

  // add m evenly spaced transverse slices to skeleton s
  void transverse(skeleton s, int m=0, int n=nslice,
		  projection P=currentprojection) {
    if(m == 0) {
      int N=size(g);
      for(int i=0; i < N; ++i)
	transverse(s,(real) i,n,P);
    } else if(m == 1)
      transverse(s,reltime(g,0.5),n,P);
    else {
      real factor=1/(m-1);
      for(int i=0; i < m; ++i)
	transverse(s,reltime(g,i*factor),n,P);
    }
  }

  // return approximate silhouette based on m evenly spaced transverse slices;
  // must be recomputed if camera is adjusted
  path3[] silhouette(int m=64, projection P=currentprojection) {
    if(is3D())
      warning("2Dsilhouette",
              "silhouette routine is intended only for 2d projections");
    path3 G,H;
    int N=size(g);
    int M=(m == 0) ? N : m;
    real factor=m == 1 ? 0 : 1/(m-1);
    int n=nslice;
    
    real tfirst=-1;
    real tlast;
    for(int i=0; i < M; ++i) {
      real t=(m == 0) ? i : reltime(g,i*factor);
      path3 S=slice(t,n);
      triple camera=camera(P);
      path3 Sp=slice(t+epsilon,n);
      path3 Sm=slice(t-epsilon,n);
      path sp=project(Sp,P);
      path sm=project(Sm,P);
      real[] t1=tangent(sp,sm,true);
      real[] t2=tangent(sp,sm,false);
      if(t1.length > 1 && t2.length > 1) {
	real t1=t1[0]/P.ninterpolate;
	real t2=t2[0]/P.ninterpolate;
	if(t1 != t2) {
	  G=G..point(S,t1);
	  H=point(S,t2)..H;
	  if(tfirst < 0) tfirst=t;
	  tlast=t;
	}
      }
    }
    int L=length(g);
    real midtime=0.5*L;
    triple camera=camera(P);
    real sign=sgn(dot(axis,camera-P.target))*sgn(dot(axis,dir(g,midtime)));

    skeleton sfirst;
    transverse(sfirst,tfirst,n,P);
    triple delta=this.M-this.m;
    path3 cap;
    if(dot(delta,axis) == 0 || (tfirst <= epsilon && sign < 0)) {
      cap=sfirst.transverse.front[0];
    } else {
      if(sign > 0) {
	if(sfirst.transverse.front.length > 0)
	  G=reverse(sfirst.transverse.front[0])..G;
      } else {
      if(sfirst.transverse.back.length > 0)
	G=sfirst.transverse.back[0]..G;
      }
    }
    
    skeleton slast;
    transverse(slast,tlast,n,P);
    if(dot(delta,axis) == 0 || (tlast >= L-epsilon && sign > 0)) {
      cap=slast.transverse.front[0];
    } else {
      if(sign > 0) {
	if(slast.transverse.back.length > 0)
	  H=reverse(slast.transverse.back[0])..H;
      } else {
	if(slast.transverse.front.length > 0)
	  H=slast.transverse.front[0]..H;
      }
    }

    return size(cap) == 0 ? G^^H : G^^H^^cap;
  }

  // add longitudinal curves to skeleton;
  // must be recomputed if camera is adjusted
  void longitudinal(skeleton s, int n=nslice, projection P=currentprojection) {
    real t, d=0;
    // Find a point on g of maximal distance from the axis.
    int N=size(g);
    for(int i=0; i < N; ++i) {
      triple v=point(g,i);
      triple center=c+dot(v-c,axis)*axis;
      real r=abs(v-center);
      if(r > d) {
        t=i;
        d=r;
      }
    }
    path3 S=slice(t,n);
    path3 Sm=slice(t+epsilon,n);
    path3 Sp=slice(t-epsilon,n);
    path sp=project(Sp,P);
    path sm=project(Sm,P);
    real[] t1=tangent(sp,sm,true);
    real[] t2=tangent(sp,sm,false);
    transform3 T=transpose(align(axis));
    real Longitude(triple v) {return longitude(T*(v-c),warn=false);}
    real ref=Longitude(point(g,t));
    real angle(real t) {return Longitude(point(S,t/P.ninterpolate))-ref;}
    triple camera=camera(P);
    void push(real[] T) {
      if(T.length > 1) {
	path3 p=rotate(angle(T[0]),c,c+axis)*g;
	path3 p1=subpath(p,0,t);
	path3 p2=subpath(p,t,length(p));
	if(length(p1) > 0 &&
	   abs(midpoint(p1)-camera) <= abs(midpoint(p2)-camera)) {
	  s.longitudinal.front.push(p1);
          s.longitudinal.back.push(p2);
	} else {
	  s.longitudinal.back.push(p1);
	  s.longitudinal.front.push(p2);
	}
      }
    }
    push(t1);
    push(t2);
  }
  
  skeleton skeleton(int m=0, int n=nslice, projection P=currentprojection) {
    skeleton s;
    transverse(s,m,n,P);
    longitudinal(s,n,P);
    return s;
  }
}

surface surface(revolution r, int n=nslice, pen color(int i, real j)=null)
{
  return r.surface(n,color);
}

// Draw on picture pic the skeleton of the surface of revolution r.
// Draw the front portion of each of the m transverse slices with pen p and
// the back portion with pen backpen. Rotational arcs are based on
// n-point approximations to the unit circle.
void draw(picture pic=currentpicture, revolution r, int m=0, int n=nslice,
	  pen frontpen=currentpen, pen backpen=frontpen,
	  pen longitudinalpen=frontpen, pen longitudinalbackpen=backpen,
	  light light=currentlight, string name="",
          real compression=defaultcompression, projection P=currentprojection)
{
  pen thin=is3D() ? thin() : defaultpen;
  skeleton s=r.skeleton(m,n,P);
  begingroup3(pic,name == "" ? "skeleton" : name,compression);
  if(frontpen != nullpen) {
    draw(pic,s.transverse.back,thin+defaultbackpen+backpen,light);
    draw(pic,s.transverse.front,thin+frontpen,light);
  }
  if(longitudinalpen != nullpen) {
    draw(pic,s.longitudinal.back,thin+defaultbackpen+longitudinalbackpen,light);
    draw(pic,s.longitudinal.front,thin+longitudinalpen,light);
  }
  endgroup3(pic);
}

revolution operator * (transform3 t, revolution r)
{
  triple trc=t*r.c;
  return revolution(trc,t*r.g,t*(r.c+r.axis)-trc,r.angle1,r.angle2);
}

// Return a right circular cylinder of height h in the direction of axis
// based on a circle centered at c with radius r.
revolution cylinder(triple c=O, real r, real h, triple axis=Z)
{
  triple C=c+r*perp(axis);
  axis=h*unit(axis);
  return revolution(c,C--C+axis,axis);
}

// Return a right circular cone of height h in the direction of axis
// based on a circle centered at c with radius r. The parameter n
// controls the accuracy near the degenerate point at the apex.
revolution cone(triple c=O, real r, real h, triple axis=Z, int n=nslice)
{
  axis=unit(axis);
  return revolution(c,approach(c+r*perp(axis)--c+h*axis,n),axis);
}

// Return an approximate sphere of radius r centered at c obtained by rotating
// an (n+1)-point approximation to a half circle about the Z axis.
// Note: unitsphere provides a smoother and more efficient surface.
revolution sphere(triple c=O, real r, int n=nslice)
{
  return revolution(c,Arc(c,r,180,0,0,0,Y,n),Z);
}
