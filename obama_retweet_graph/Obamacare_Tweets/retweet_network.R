library(igraph)
library(dplyr)

load("/Users/CDX/Google\ Drive/twitter_politics_data/obamacare.RData")# The data list is saved
length(obamacare)
##### 1. data structure ####
# str(obamacare[[101010]])
# obamacare[[101010]]$text
# obamacare[[101010]]$user$screen_name# @screen_name unique
# obamacare[[101010]]$user$id
# obamacare[[101010]]$user$name# may be duplicated
# obamacare[[101010]]$retweeted_status$user$screen_name# retweet from
# obamacare[[101010]]$retweeted_status$user$name   
# obamacare[[101010]]$retweeted_status$user$id
# i=0
# while(T){
#   i=i+1
#   if(identical(obamacare[[i]]$user$screen_name,"mattklewis")
#      &identical(obamacare[[i]]$text,"If ObamaCare is overturned, George W. Bush's greatest legacy might be ... Roberts and Alito. http://t.co/y0WxraPM")){
#     print(i)
#   }else{if(i=length(obamacare)) break}
# }

# str(obamacare[[100904]])
# str(obamacare[[105505]])
# obamacare[[100904]]$retweeted_status#original (=NULL)

#### make edge list ####
edge<-function(x){
  if(identical(NULL,x$retweeted_status)) return(c(NA,NA))
  else{
    return(c(x$user$id,x$retweeted_status$user$id))
  }
}

edge_list<-t(sapply(obamacare,FUN = edge))
colnames(edge_list)<-c("post","retweet_from")
edge_list<-edge_list[!is.na(edge_list[,1]),]
edge_list<-as.data.frame(edge_list,stringsAsFactors = F)

weight<-table(edge_list$retweet_from)
weight<-as.data.frame(weight,stringsAsFactors = F);names(weight)<-c("id","weight")
head(weight)


#### make vertices list ####
vertices_list<-t(sapply(obamacare,FUN = function(x) c(x$user$id_str,x$user$name)))

vertices2<-function(x){
  if(!identical(NULL,x$retweeted_status)) return(c(x$retweeted_status$user$id_str,x$retweeted_status$user$name))
  else return(c(NA,NA))
}

vertices_list2<-t(sapply(obamacare,FUN = vertices2))
vertices_list2<-vertices_list2[!is.na(vertices_list2[,1]),]


vertices_list<-rbind(vertices_list,vertices_list2)
colnames(vertices_list)<-c("id","name")
vertices_list<-as.data.frame(vertices_list,stringsAsFactors = F)

library(dplyr)
vertices_list<-distinct(select(vertices_list,id,name)) 
vertices_list<-vertices_list[!duplicated(vertices_list$id),]#delete the duplicated item

setdiff(union(edge_list$post,edge_list$retweet_from),vertices_list$id)#varify the completeness

#add attr weight
vertices_list<-merge(vertices_list,weight,all.x=T)
vertices_list[is.na(vertices_list$weight),3]<-0
head(vertices_list)
length(vertices_list[,1])

#### network graph ####  
suppressMessages(library(igraph))

#deal with the name strings
library(stringr)
vertices_list$name[is.na(str_length(vertices_list$name))]#multi-byte strings  
head(iconv(vertices_list$name, "latin1", "ASCII", sub=""))  
vertices_list$name<-iconv(vertices_list$name, "latin1", "ASCII", sub="")
v<-vertices_list #for the reason of wrong namek

# GRAPH OBJECT
#layout
fruch = layout.fruchterman.reingold(net)
circle=layout.circle(net)
net<-graph.data.frame(d=edge_list,v=v ,directed=T) 

png(filename = "retweet_graph2.png",width=1400,height=850)
par(mar=c(0,0,0,0))
plot(net, edge.arrow.size=.2, edge.color="orange"
     ,vertex.label = ifelse(V(net)$weight>1000,V(net)$name,NA)
     ,vertex.color="red"
     ,vertex.size=ifelse(V(net)$weight>1000,1.2,0.2)
     ,vertex.frame.color=rgb(.25, .5, .3,alpha=ifelse(V(net)$weight>1000,1,0.2))
     ,vertex.label=NA, vertex.label.color="black") 

# add title
title("\nTweets with 'obamacare':  Who retweets whom",
      cex.main=1, col.main="black",family="mono") 

dev.off()

### delete the meaningless vertex  

# cut.off <- 1000
# net.sp <- delete.edges(net, E(net)[weight<cut.off])
# l <- layout.fruchterman.reingold(net.sp, repulserad=vcount(net)^2.1) 
# plot(net.sp, layout=l)


