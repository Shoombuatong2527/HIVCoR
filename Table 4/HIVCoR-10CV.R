#######set directory
setwd('D:\\CRF_01AE')
#######Load package
library(randomForest)
library(kernlab)
library(e1071)
library(randomForest)
library(protr)
library(seqinr)
library(AUC)
library(ROCR)
library(RWeka)
library(caret)

customRF <- list(type = "Classification", library = "randomForest", loop = NULL)
customRF$parameters <- data.frame(parameter = c("mtry", "ntree"), class = rep("numeric", 2), label = c("mtry", "ntree"))
customRF$grid <- function(x, y, len = NULL, search = "grid") {}
customRF$fit <- function(x, y, wts, param, lev, last, weights, classProbs, ...) {
  randomForest(x, y, mtry = param$mtry, ntree=param$ntree, ...)
}
customRF$predict <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata)
customRF$prob <- function(modelFit, newdata, preProc = NULL, submodels = NULL)
   predict(modelFit, newdata, type = "prob")
customRF$sort <- function(x) x[order(x[,1]),]
customRF$levels <- function(x) x$classes
######### Extract feature
x1 <- read.fasta('CCR5 AA.fasta', seqtype="AA", as.string = TRUE)
x2 <- read.fasta('CXCR4 AA.fasta', seqtype="AA", as.string = TRUE)
x1 <- x1[(sapply(x1, protcheck))]
x2 <- x2[(sapply(x2, protcheck))]
AUC <- matrix(nrow = 5, ncol = 1)

col = 20+ 30
PAAC1  <- matrix(nrow = length(x1), ncol = col)
for (i in 1:length(x1)){
PAAC1[i,] = extractPAAC(x1[[i]][1], props = c("Hydrophobicity", "Hydrophilicity", "SideChainMass"),lambda = 30, w = 0.05, customprops = NULL)
}

PAAC2  <- matrix(nrow = length(x2), ncol = col)
for (i in 1:length(x2)){
PAAC2[i,] = extractPAAC(x2[[i]][1], props = c("Hydrophobicity", "Hydrophilicity", "SideChainMass"),lambda = 30, w = 0.05, customprops = NULL)
}

PAAC3 <-PAAC1[!duplicated(PAAC1), ]
PAAC4 <-PAAC2[!duplicated(PAAC2), ]

label =  c(rep("R5",nrow(PAAC3)),rep("X4",nrow(PAAC4)))
internal = data.frame(rbind(PAAC3,PAAC4),Class = label)
AUC <- matrix(nrow = 5, ncol = 1)

tunegrid <- expand.grid(.mtry=c(1:5), .ntree=seq(100,500,100))
RFmodel <- train(Class~., data=internal , method=customRF, metric=c("Accuracy"), tuneGrid=tunegrid, trControl=trainControl(method = "cv", number=10))
Resultcv = RFmodel$ finalModel$ confusion [,1:2]
pred=prediction(RFmodel$ finalModel$ votes[,2],internal[,ncol(internal)])
perf_AUC=performance(pred,"auc") #Calculate the AUC value
AUCtr = perf_AUC@y.values[[1]]

data = Resultcv
	ACCtr = (data[1]+data[4])/(data[1]+data[2]+data[3]+data[4])*100
	SENStr  =  (data[1]/(data[1]+data[2]))*100
	SPECtr = (data[4])/(data[3]+data[4])*100
	MCC1      = (data[1]*data[4]) - (data[3]*data[2])
	MCC2      =  (data[4]+data[2])*(data[4]+data[3])
	MCC3      =  (data[1]+data[2])*(data[1]+data[3])
	MCC4	=  sqrt(MCC2)*sqrt(MCC3)
	MCCtr  = MCC1/MCC4

round(data.frame (ACCtr,SPECtr,SENStr,MCCtr,AUCtr),2)
