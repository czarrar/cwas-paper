library(ggplot2)

#' loads 3 variables: orig, boot.repl, boot.norepl
#+ load
load("/home2/data/Projects/CWAS/nki/bootstrap/compare_replication.rda")

#' Will calculate dice pairwise between columns
#' input `mat` should be boolean or integer of 0 and 1s
dice <- function(mat) {
  # (2*sum(a&b))/(sum(a)+sum(b))

  # This gets the number of elements in common between a & b
  sum.anb <- crossprod(mat)
  
  # We can get the sum in each set with the diagonal
  sum.a <- diag(sum.anb) %*% t(rep(1,ncol(mat)))
  sum.b <- t(sum.a)
  
  # Let's combine
  dice.mat <- (2*sum.anb)/(sum.a+sum.b)
  
  dice.mat
}