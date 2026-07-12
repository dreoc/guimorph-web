# =====================================================================
#  gm_utils.R -- small geometric-morphometric helpers used by GUImorph's
#  surface / TPS / plotting code.
#
#  GUImorph calls live geomorph (>= 4.1.1) for all analysis (gpagen,
#  gm.prcomp, two.d.array). These few generic utilities are all that
#  remained in use from the former vendored copy (geomorph.support.code.r),
#  which has been retired.
#
#  tps2d3d is altered from J. Claude (2008), "Morphometrics with R".
#  center / csize / cs.scale / rotate.mat / fast.ginv / fast.solve are
#  standard Procrustes / linear-algebra utilities.
# =====================================================================

# startup module tag (debug banner only)
get_geomorph_support_date <- function() dbg("GUImorph 0.9.0 - geomorph support")

center <- function(x){
  if(is.vector(x)) x- mean(x) else {
    x <- as.matrix(x)
    x - rep(colMeans(x), rep.int(nrow(x), ncol(x)))
  }
}

# centroid size
csize <- function(x) sqrt(sum(center(as.matrix(x))^2))

# divide a configuration by its centroid size
cs.scale <- function(x) x/csize(x)

rotate.mat <- function(M,Y){
  k <- ncol(M)
  M <- cs.scale(M); Y <- cs.scale(Y)
  MY <- crossprod(M,Y)
  sv <- La.svd(MY,k,k)
  u <- sv$u; u[,k] <- u[,k]*determinant(MY)$sign
  v <- t(sv$vt)
  tcrossprod(v,u)
}

fast.ginv <- function(X, tol = sqrt(.Machine$double.eps)){
  k <- ncol(X)
  Xsvd <- La.svd(X, k, k)
  Positive <- Xsvd$d > max(tol * Xsvd$d[1L], 0)
  rtu <-((1/Xsvd$d[Positive]) * t(Xsvd$u[, Positive, drop = FALSE]))
  v <-t(Xsvd$vt)[, Positive, drop = FALSE]
  v%*%rtu
}

fast.solve <- function(x) if(det(x) > 1e-8) qr.solve(x) else fast.ginv(x)

tps2d3d<-function(M, matr, matt, PB=TRUE){    #DCA: altered from J. Claude 2008
  p<-dim(matr)[1]; k<-dim(matr)[2];q<-dim(M)[1]
  Pdist<-as.matrix(dist(matr))
  ifelse(k==2,P<-Pdist^2*log(Pdist^2),P<- Pdist)
  P[which(is.na(P))]<-0
  Q<-cbind(1, matr)
  L<-rbind(cbind(P,Q), cbind(t(Q),matrix(0,k+1,k+1)))
  m2<-rbind(matt, matrix(0, k+1, k))
  coefx<-fast.solve(L)%*%m2[,1]
  coefy<-fast.solve(L)%*%m2[,2]
  if(k==3){coefz<-fast.solve(L)%*%m2[,3]}
  fx<-function(matr, M, coef, step){
    Xn<-numeric(q)
    for (i in 1:q){
      Z<-apply((matr-matrix(M[i,],p,k,byrow=TRUE))^2,1,sum)
      ifelse(k==2,Z1<-Z*log(Z),Z1<-sqrt(Z)); Z1[which(is.na(Z1))]<-0
      ifelse(k==2,Xn[i]<-coef[p+1]+coef[p+2]*M[i,1]+coef[p+3]*M[i,2]+sum(coef[1:p]*Z1),
             Xn[i]<-coef[p+1]+coef[p+2]*M[i,1]+coef[p+3]*M[i,2]+coef[p+4]*M[i,3]+sum(coef[1:p]*Z1))
      if(PB==TRUE){setTxtProgressBar(pb, step + i)}
    }
    Xn}
  matg<-matrix(NA, q, k)
  if(PB==TRUE){pb <- txtProgressBar(min = 0, max = q*k, style = 3) }
  matg[,1]<-fx(matr, M, coefx, step = 1)
  matg[,2]<-fx(matr, M, coefy, step=q)
  if(k==3){matg[,3]<-fx(matr, M, coefz, step=q*2)
  }
  if(PB==TRUE) close(pb)
  matg
}
