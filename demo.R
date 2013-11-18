library(Rook)
 
newapp<-function(env){
 req<-Rook::Request$new(env)
 res<-Rook::Response$new()
 
 carrid_param<-c(req$params()$carrid)
 seats_param<-c(req$params()$seats)
 
 carrid_param<-strsplit(carrid_param,",")
 carrid_param<-c(carrid_param[[1]][1],carrid_param[[1]][2],
                 carrid_param[[1]][3])
 seats_param<-strsplit(seats_param,",")
 seats_param<-c(as.numeric(seats_param[[1]][1]),as.numeric(seats_param[[1]][2]),
                as.numeric(seats_param[[1]][3]))

 params<-data.frame(carrid_param,seats_param)

 bmp("R_Plot.bmp",type=c("cairo"))
 dotchart(params$seats_param,labels=params$carrid_param,
          xlab="Number of seats",ylab="Carriers")
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