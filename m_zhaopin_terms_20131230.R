
#���﷢��ģ�͵�һ�� 20131229
#���ݷ���ʦ�����е�רҵ����

#��ְλ�����а����ٽ���ϵ�Ѵ���ѡ��
#����2���﷨�ṹɸѡ����
#����Ƶ��ɸѡ����
#�˹���ѡɸ��������������ݿ�

# ��ȡԭʼ����
library(RODBC)
con <- odbcConnect( "aliecs" , uid ="dcshallot", pwd = "1m1nd1" )
txt.org <- sqlQuery(con, "select content from ods_datanalyst_zhaopin limit 1000") 
close(con); rm(con)
txt <- as.character( txt.org[1:500,])  #һ������������Ӧ����1000������1�˴�������

#�ִʹ�����ϴ
txt <- tolower(txt)
txt <- gsub( "[[:digit:]]", " ", txt)
txtplain <- paste( txt, collapse= " ")
library(Rwordseg)
uninstallDict()
seg <- segmentCN( txt , nature=T )  #�����Եķִ�


####���ݴ��Զ�Ӧ��ʵ�ʴ�ȷ���﷨���˹���
#x <- segmentCN( as.character(txt.org[,1]), nature=T)
#x <- unlist(x)
#x <-as.data.frame( cbind( x, names(x)))
#y <- unique( as.character( x[,2]) )
#b <- data.frame()
#for ( i in 1: length(y) )  {
#  z <- paste( unique( as.character( x[ x$V2 == y[i] , 1] ) )[1:20], collapse="," )
#  a <- cbind.data.frame( y[i] , z, stringsAsFactors = F)
#  b <- rbind(a, b)
#} 
#write.csv(b, "d:/d.csv");rm(x,y,b,z,a)####��Ҫ����N=, A=, V=

#�����ݱ�
x <- unlist(seg)
y <- names(x)
worddata <- cbind.data.frame( x, y, stringsAsFactors = F )
worddata <- unique(worddata)
names(worddata) <- c("w","pt") ;rm(x,y)
worddata <- worddata[ !grepl( "uj|p|ug|c", worddata$pt) , ] #����ɸѡ
worddata$id <- 1:nrow(worddata) #����
l <- aggregate( worddata$id, by=list( worddata$w), FUN=min) #���غ�����
l <- sort( l[, ncol(l)] )
worddata <- worddata[l, ]
worddata <- worddata[,-3] #������������id
worddata$wfrq <- sapply( worddata$w, function(x) length( gregexpr(x, txtplain)[[1]] ))
#���������ѡ��
require(tau)
terms <- textcnt(seg, split = " ", method = "string", n = 2) #2���д�
terms <- terms[ terms> 3 ]  #�����Ƶɸѡ
#��������ɸѡ��
tname <- names(terms)
w1 <- sapply( tname, function(x) strsplit( x, " ") [[1]] [1])
w2 <- sapply( tname, function(x) strsplit( x, " ") [[1]] [2])
termdata <- cbind.data.frame( tname, w1, w2, stringsAsFactors = F )
termdata$tfrq <- sapply( termdata[,1], function(x) length( gregexpr( gsub(" " ,"", x) , txtplain)[[1]] ))
termdata <- termdata[ termdata$tfrq > 3,]
#����+�� 
data <- merge( termdata, worddata, by.x="w1", by.y="w")
data <- merge(data, worddata, by.x="w2", by.y="w")
data <- data[, c(3,4,5,7,2,6,1,8)]
names(data)[3:8] <- c("ptl","ptr","wl","frql","wr","frqr")
#tdata <- tdata[ tdata$tfreq > quantile(tdata$tfreq, prob = .25 ) , ] #���ݴ�Ƶɸѡ

tdata <- data
names(tdata)
tdata$intinfo <- tdata$tfrq/tdata$frql/tdata$frqr #����Ϣ
tdata$termhood <- tdata$tfrq*( length(txt)-tdata$tfrq)/length(txt) #termhood

write.csv( tdata, "d:/term.csv", row.names=F) 
#�������˹�����֮���ٶ�������д�����ݿ�
#######################################################################
model.data <- read.csv("d:/term.csv",header=T)
#�洢
library(RODBC)
con <- odbcConnect( "aliecs" , uid ="dcshallot", pwd = "1m1nd1" )
#sqlQuery(con, "TRUNCATE dbh57f6095rv6n96.dim_zhaopin_term1")
sqlSave(con, model.data , tablename = "ods_termstudy_data1", append = T, rownames = F, addPK = FALSE)
close(con)
#����ѧϰģ���о�
names(model.data)
model.data$y <- sapply( model.data$y, function(x) if (x>0) 1 else 0)
logi <- glm( y~ ptl*ptr, model.data, family="binomial")
b <- step( logi)
summary(b)
D D D
ye1 <- model.data[ model.data$y=="1", c(3,4)]