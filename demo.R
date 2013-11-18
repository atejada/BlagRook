library(Rook)
 
newapp<-function(env){
 req<-Rook::Request$new(env)
 res<-Rook::Response$new()
 
 carrid_param<-c(req$params()$carrid)
 seats_param<-c(req$params()$seats)
 seats_param<-as.numeric(seats_param)

  bmp("R_Plot.bmp",type=c("cairo"))
  barplot(seats_param,names.arg=carrid_param)
#  graph<-data.frame(c(1,2,3),c(4,5,6))
#  plot(graph)
  dev.off()
  
  to.read = file("R_Plot.bmp", "rb")
  x<-readBin(to.read, raw(),n=231488)
  hex<-paste(x, collapse = "")

  res$write(hex)
 
  res$finish()
}
 
 
server = Rhttpd$new()
server$add(app = newapp, name = "summarize")
server$start(listen="0.0.0.0", port=as.numeric(Sys.getenv("PORT")))
 
 
while(T) {
  Sys.sleep(10000)
}