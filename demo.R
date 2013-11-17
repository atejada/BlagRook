library(Rook)
 
newapp<-function(env){
  req<-Rook::Request$new(env)
  res<-Rook::Response$new()
 
  name_param = req$params()$name
 
  bmp("R_Plot.bmp",type=c("cairo"))
  test<-data.frame(c(1,2,3),c(4,5,6))
  plot(test)
  dev.off()
  
  to.read = file("R_Plot.bmp", "rb")
  readBin(to.read, raw(),n=1L)
  x<-readBin(to.read, raw(),n=231488)
  test<-paste(x, collapse = "")

  print(test)
  res$write(test)
 
  res$finish()
}
 
 
server = Rhttpd$new()
server$add(app = newapp, name = "summarize")
server$start(listen="0.0.0.0", port=as.numeric(Sys.getenv("PORT")))
 
 
while(T) {
  Sys.sleep(10000)
}