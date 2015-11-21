#################################################
#                                               #
#   CAPSTONE PROJECT: YELP DATA CHALLENGE       #
#               FINAL SCRIPT                    #
#                                               #
#################################################

#----SET UP ENVIRONMENT ---

#set working directory to CAPSTONE folder
setwd("C:/Users/mhertneck/Google Drive/Coursera_Data_Scientist/Capstone")

# load packages
library(doParallel) # for speed by using multiple cores
library(beepr) # for an alert when needed
library(jsonlite) # for reading json data into R & unpacking
library(stringr) # for gsub
#library(psych) # for describeBy function
#library(perturb) # to test condition indices
#library(car) # for VIF on regression

registerDoParallel(4) # optimize use of cores
memory.limit(4095) #increase memory limit


#---- GET JSON DATA ----

# unzip and load data
unzip("yelp_dataset_challenge_academic_dataset.zip")
#beep("work_complete.wav")

#----View Business Data----

# #Read the first line of data under business.json
# first_line = readLines(paste("./yelp_dataset_challenge_academic_dataset/yelp_academic_dataset_business.json", sep=""), n = 1)
# 
# #Convert record to an R list
# first_list = fromJSON(first_line)
# str(first_list)
# 
# #view in JSON format
# toJSON(first_list, pretty = TRUE)

#----Load Business Data----

# slightly different import due to unstructured json file:
# elapsed time = 36.69 (~ 0.5 minute) and 61,184 observations of 15 variables
system.time(business <- stream_in(file("./yelp_dataset_challenge_academic_dataset/yelp_academic_dataset_business.json")))
business <- flatten(business)
#beep("C:/Windows/Media/Alarm05.wav")

#---sampling business data: Phoenix only---

business.phx <- business[business$city =="Phoenix",] # pulling only Phoenix for now

# Write PHX business IDs to a csv file for use in choosing Review/Tip data
write.csv(business.phx$business_id, file = "phxbusID.csv", row.names = FALSE, col.names = FALSE)

busID <- read.csv("phxbusID.csv", col.names="business_id", stringsAsFactors=FALSE) # read business ids back in
busID <- cbind(busID,business.phx$open)

#----Load Review Data----

# elapsed time = 249.34 (~ 4+ minutes) and 1,569,264 observations of 8 (11) variables
system.time(review <- stream_in(file("./yelp_dataset_challenge_academic_dataset/yelp_academic_dataset_review.json")))
review <- flatten(review)
#beep("C:/Windows/Media/Alarm05.wav")

#---sampling Review data: Phoenix businesses only---

# select only the reviews for PHX businesses
review.phx <- review[which(review$business_id %in% busID$business_id),]
review.phx$date<- as.Date(review.phx$date,"%Y-%m-%d") # format dates 
review.phx <- review.phx[order(review.phx$business_id,review.phx$date, decreasing=TRUE),] # order by business id and date (decreasing)

#----Load Tip Data----

# elapsed time = 25.69 (~ 0.5 minutes) and 495,107 observations of 6 variables
system.time(tip <- stream_in(file("./yelp_dataset_challenge_academic_dataset/yelp_academic_dataset_tip.json")))
tip <- flatten(tip)
#beep("C:/Windows/Media/Alarm05.wav")

#---sampling Tip data: Phoenix businesses only---

# select only the tips for PHX businesses
tip.phx <- tip[which(tip$business_id %in% busID$business_id),] 
tip.phx$date<- as.Date(tip.phx$date,"%Y-%m-%d") # format dates 
tip.phx <- tip.phx[order(tip.phx$business_id,tip.phx$date, decreasing=TRUE),] # order by business id and date (decreasing)

# --- cleanup ---
rm(business, review, tip,busID)



###----- CLEAN AND FORMAT DATA/FEATURE CREATION -----

# ----- unlisting the categories variable for a business into a new dataframe---

catnames.x <- unlist(business.phx$categories)
catnames <- unique(unlist(business.phx$categories)) 

#create empty data.frame with category headings & ID
temp.cat <- data.frame(matrix(ncol = length(catnames), nrow = nrow(business.phx))) # empty data.frame
colnames(temp.cat) <- catnames # column names
temp.cat <- cbind(business_id=business.phx$business_id,temp.cat) # add business_ID
temp.cat$business_id <- as.character(temp.cat$business_id) #change factor to string

# populate dataframe with material from categories list in business.phx
#elapsed time is ~0.5 minutes

system.time(
    for (i in 1:nrow(business.phx)) {
        
        x <- business.phx$business_id[i]
        templist <- unlist(business.phx$categories[business.phx$business_id==x]) # convert one list of elements to vector
        
        for (j in 1:length(templist)) {         #for each item in templist...
            
            templist[j] # item to check in vector
            z <- which(colnames(temp.cat) %in% templist[j]) # matches column name and provides column index
            temp.cat[temp.cat$business_id==x,z] <- 1 # inserts "1" in correct column/row by business name
            
        } #endif
    } #endif
) #end sys time
#beep("C:/Windows/Media/Alarm05.wav")
rm(i,j,x,z,templist)

colnames(temp.cat) <- paste("cat", colnames(temp.cat), sep = ".")

catnames <- make.names(colnames(temp.cat), unique = TRUE, allow_ = TRUE) #make sure string names are syntactically correct
catnames <- gsub("..", ".", catnames, fixed = TRUE) # get rid of extra "."
catnames <- gsub("..", ".", catnames, fixed = TRUE) # get rid of extra "." (do it again)
catnames <- catnames[-1]
colnames(temp.cat) <- c("business_id",catnames) # rename temp.cat columns with valid names

rm(catnames.x, catnames)

#transform NAs into zeros
temp.cat <- replace(temp.cat, is.na(temp.cat), 0) 

#check the sum of each category and remove anything with less than 2 
allsum <- sort(colSums(temp.cat[,-1],na.rm=TRUE)) # sum of each column
fivesum <- names(allsum[allsum<2]) # names of each column where sum is <2
temp.cat <- temp.cat[,!(names(temp.cat) %in% fivesum)] #remove columns with five sum
rm(allsum,fivesum)

# merge temp.cat with original PHX business data  
business.phx <- merge(business.phx,temp.cat, by.x = "business_id", by.y = "business_id")
#names(business.phx)
rm(temp.cat)

# ---- BUSINESS.PHX: remove unnecessary variables ---
business.phx$type <- NULL
business.phx$full_address <- NULL
business.phx$city <- NULL
business.phx$name <- NULL
business.phx$categories <- NULL # no longer need this variable
business.phx$neighborhoods <- NULL # no data apparent; empty


# ----- make sure names are syntactically correct -----

xnames <- make.names(colnames(business.phx), unique = TRUE, allow_ = TRUE) #make sure string names are syntactically correct
xnames <- gsub("..", ".", xnames, fixed = TRUE) # get rid of extra "."
xnames <- gsub("..", ".", xnames, fixed = TRUE) # get rid of extra "." (do it again)
colnames(business.phx) <- xnames # rename columns with valid names
rm(xnames)

# ----- unlist the attributes.Accepts Credit Cards variable for a business into a new dataframe---

atnames <- names(business.phx[str_detect(names(business.phx), "attributes")]) # ID pertinent variable names
str(business.phx[str_detect(names(business.phx), "attributes")]) #ID lists (only 1)

creditnames.x <- unlist(business.phx$attributes.Accepts.Credit.Cards)
creditnames <- unique(unlist(business.phx$attributes.Accepts.Credit.Cards)) 

temp.credit <- data.frame(matrix(ncol = length(creditnames), nrow = nrow(business.phx)))
colnames(temp.credit) <- creditnames

temp.credit <- cbind(business_id=business.phx$business_id,temp.credit)


# populate dataframe with material from attributes.Accepts.Credit.Cards list in business.phx
# elapsed time is ~0.5 minutes)
system.time(
    for (i in 1:nrow(business.phx)) {
        
        x <- business.phx$business_id[i]
        templist <- unlist(business.phx$attributes.Accepts.Credit.Cards[business.phx$business_id==x]) # convert one list of elements to vector
        
        #j <- length(templist) # identify how many vector elements
        
        for (j in 1:length(templist)) {         #for each item in templist...
            
            templist[j] # item to check in vector
            z <- which(colnames(temp.credit) %in% templist[j]) # matches column name and provides column index
            temp.credit[temp.credit$business_id==x,z] <- 1 # inserts "1" in correct column/row by business name
            
        } #endif
    } #endif
) #end sys time
#beep("C:/Windows/Media/Alarm05.wav")
rm(i,j,x,z,templist)

# turn into numeric variables instead of dummy variables; 1=TRUE, 0=FALSE
temp.credit$CreditCard[temp.credit[2]==1] <- 1 # binary TRUE
temp.credit$CreditCard[temp.credit[3]==1] <- 0 # binary FALSE
temp.credit[2] <- NULL
temp.credit[2] <- NULL

#transform NAs into zeros
temp.credit <- replace(temp.credit, is.na(temp.credit), 0) 

# merge temp.credit with original PHX business data
business.phx <- merge(business.phx,temp.credit, by.x = "business_id", by.y = "business_id")

business.phx$attributes.Accepts.Credit.Cards <-NULL #remove original messy variable

rm(creditnames,creditnames.x,temp.credit,atnames)


#----- clean up attributes.XXX in business.phx-----

atnames <- names(business.phx[str_detect(names(business.phx), "attributes")]) # ID pertinent variable names

system.time(
    for (i in 1:length(atnames)) {
        if(is.logical(business.phx[,atnames[i]])) {
            
            business.phx[,atnames[i]][business.phx[,atnames[i]]==TRUE] <- 1 # binary TRUE
            business.phx[,atnames[i]][business.phx[,atnames[i]]==FALSE] <- 0 # binary FALSE
            business.phx[,atnames[i]] <- replace(business.phx[,atnames[i]], is.na(business.phx[,atnames[i]]), 0) #transform NAs into zeros
        } #endif
        
        else if (is.character(business.phx[,atnames[i]])| is.integer(business.phx[,atnames[i]])){
            business.phx[,atnames[i]] <- factor(business.phx[,atnames[i]]) # convert to factor
        } #endif
    }#endfor
) #end sys time
#beep("C:/Windows/Media/Alarm05.wav")
rm(i)

# check factor attributes and consolidate/clean if necessary
factnames <- names(Filter(is.factor, business.phx[atnames])) #ID your factors

#observations...
#   attributes.Noise.Level could be consolidated into 3 levels instead of 4 (combine loud & very_loud)
#   attributes.Attire - combine dressy & formal
#   attributes.Smoking - combine outdoor & yes
#   attributes.Ages.Allowed - not enough to change but could make into binary if desired

levels(business.phx$attributes.Noise.Level) <- c("average","loud","quiet","loud") #group two levels together
levels(business.phx$attributes.Attire) <- c("casual","dressy","dressy")
levels(business.phx$attributes.Smoking) <- c("no","yes","yes")


#----- corkage and BYOB consolidation-----

temp.byob <- as.data.frame(cbind(attributes.BYOB=business.phx$attributes.BYOB, 
                                 attributes.Corkage=business.phx$attributes.Corkage,
                                 attributes.BYOB.Corkage=business.phx$attributes.BYOB.Corkage)) #temp subset

temp.byob$attributes.BYOB.Corkage <- as.factor(temp.byob$attributes.BYOB.Corkage) #format as factor w/ levels
levels(temp.byob$attributes.BYOB.Corkage) <- c("no","yes_corkage","yes_free")

# adjust primary variable
temp.byob$attributes.BYOB.Corkage[temp.byob$attributes.BYOB==1] <- "yes_free"
temp.byob$attributes.BYOB.Corkage[temp.byob$attributes.Corkage==1] <- "yes_corkage"

business.phx$attributes.BYOB.Corkage <- temp.byob$attributes.BYOB.Corkage # replace business.phx variable with edited variable

business.phx$attributes.BYOB <- NULL # remove extraneous variable
business.phx$attributes.Corkage <- NULL # remove extraneous variable

rm(temp.byob)

# ----Kids consolidation ------

sort(names(business.phx[str_detect(names(business.phx), fixed("kids", ignore_case=TRUE))])) #look for similaries

business.phx$attributes.kids <- NA

# adjust primary variable
business.phx$attributes.kids[business.phx$attributes.Good.for.Kids==1] <- 1
business.phx$attributes.kids[business.phx$attributes.Good.For.Kids==1] <- 1
business.phx$attributes.kids[business.phx$attributes.Hair.Types.Specialized.In.kids==1] <- 1
business.phx$attributes.kids[business.phx$Kids.Activities==1] <- 1

business.phx$attributes.kids[is.na(business.phx$attributes.kids) & business.phx$attributes.Good.for.Kids==0] <- 0
business.phx$attributes.kids[is.na(business.phx$attributes.kids) & business.phx$attributes.Good.For.Kids==0] <- 0
business.phx$attributes.kids[is.na(business.phx$attributes.kids) & business.phx$Kids.Activities==0] <- 0

business.phx$attributes.Good.for.Kids <- NULL
business.phx$attributes.Good.For.Kids <- NULL
business.phx$attributes.Hair.Types.Specialized.In.kids <- NULL
business.phx$Kids.Activities <- NULL

rm(factnames)

# ---- REVIEWS: sample and test for max dates ---

# max date for each business id
d <- aggregate(review.phx$date,by=list(review.phx$business_id),max)
colnames(d) <- c("business_id","maxdatereview")

# merge maxdates with original PHX business data
business.phx <- merge(business.phx,d, by.x = "business_id", by.y = "business_id")

# ---- TIPS: sample and test for max dates ---

# max date for each business id
d <- aggregate(tip.phx$date,by=list(tip.phx$business_id),max)
colnames(d) <- c("business_id","maxdatetip")

# merge maxdates with original PHX business data
business.phx <- merge(business.phx,d, by.x = "business_id", by.y = "business_id")

rm(d,tip.phx)

# Compare maxdatereview against maxdatetip and keep most current date as maxdatefinal
business.phx$maxdatefinal <- pmax(business.phx$maxdatereview, business.phx$maxdatetip,na.rm=TRUE) 

# ---- find review record with last date and obtain star rating---

business.phx$laststar <- NA  # create empty column for last star rating

# populate last star rating column (~1.5 minutes)
system.time(
    for (i in 1:nrow(business.phx)) {
        
        temp <-review.phx[review.phx$business_id==business.phx$business_id[i],]
        temp <- temp[order(temp$date, decreasing=TRUE),]
        temp <- temp[1,] # keep only first row w/ max date
        business.phx$laststar[i] <- temp$stars[1]
        rm(temp)
        rm(i)
        
    } #endfor
)
#beep("C:/Windows/Media/Alarm05.wav")

# ----- create binned variable in business.phx on review_count ---

bins<-10 # number of bins desired
cutpoints<-quantile(business.phx$review_count,(0:bins)/bins,na.rm=TRUE)
cutpoints <- round(cutpoints,0)

#perform the binning
business.phx$reviewbin <-cut(business.phx$review_count,cutpoints,include.lowest=TRUE)
rm(bins,cutpoints)

# ----- create number of days back set from maxdatefinal ---

# before loop, add X number of columns to business.phx for X days from last review
business.phx$numDays1back <- NA
business.phx$numDays2back <- NA
business.phx$numDays3back <- NA

# elapsed time is ~4.25 minutes
system.time(
    for (i in 1:nrow(business.phx)) {
        #create subset of reviews based on business_id
        temp <-review.phx[review.phx$business_id==business.phx$business_id[i],]
        temp <- temp[order(temp$date, decreasing=FALSE),]
        # check if date is available    
        ifelse(nrow(temp)<=1,back1 <- NA, back1 <- temp$date[nrow(temp)]-temp$date[nrow(temp)-1])
        ifelse(nrow(temp)<=2,back2 <- NA, back2 <- temp$date[nrow(temp)]-temp$date[nrow(temp)-2])
        ifelse(nrow(temp)<=3,back3 <- NA, back3 <- temp$date[nrow(temp)]-temp$date[nrow(temp)-3])
        #place values in business.phx
        business.phx$numDays1back[i] <- back1
        business.phx$numDays2back[i] <- back2
        business.phx$numDays3back[i] <- back3
        # cleanup
        rm(temp,i,back1,back2,back3)
    } #endfor
) #end system.time
#beep("C:/Windows/Media/Alarm05.wav")

# ----- create number-of-days-between reviews ---

business.phx <- within(business.phx, Diff2 <- numDays2back-numDays1back)
business.phx <- within(business.phx, Diff3 <- numDays3back-numDays2back)

#convert the item with NA to 9999 from the column  (zeros would not be appropriate here)
business.phx$Diff2[is.na(business.phx$Diff2)] <- 9999 
business.phx$Diff3[is.na(business.phx$Diff3)] <- 9999 

# ----- create average of last X stars for X reviews (up to 3 dates back) ---

#elapsed time is ~1.5 minutes
system.time(
    for (i in 1:nrow(business.phx)) {
        #create subset of reviews based on business_id
        temp <-review.phx[review.phx$business_id==business.phx$business_id[i],]
        temp <- temp[order(temp$date, decreasing=FALSE),]
        # check if date is available    
        ifelse(nrow(temp)<=1,back1star <- NA, back1star <- (temp$star[nrow(temp)]+temp$star[nrow(temp)-1])/2)
        ifelse(nrow(temp)<=2,back2star <- NA, back2star <- (temp$star[nrow(temp)]+temp$star[nrow(temp)-1]+temp$star[nrow(temp)-2])/3)
        ifelse(nrow(temp)<=3,back3star <- NA, back3star <- (temp$star[nrow(temp)]+temp$star[nrow(temp)-1]+temp$star[nrow(temp)-2]+temp$star[nrow(temp)-3])/4)
        #place values in business.phx
        business.phx$numStars1back[i] <- back1star
        business.phx$numStars2back[i] <- back2star
        business.phx$numStarsback[i] <- back3star
        # cleanup
        rm(temp,i,back1star,back2star,back3star)
    } #endfor
) #end sys time
#beep("C:/Windows/Media/Alarm05.wav")

# ----- Impute missing Star rating variables ---

length(which(is.na(business.phx$numStarsback)))/nrow(business.phx) # 11% Missing - NumStarsback, etc. are usable; impute means

df <- cbind(numStarsback=business.phx$numStarsback,numDays3back=business.phx$numDays3back,
            numDays2back=business.phx$numDays2back,numStars1back=business.phx$numStars1back, numStars2back=business.phx$numStars2back,
            numDays1back=business.phx$numDays1back) # to isolate columns that need fixing 

f <- function(x){ 
    x<-as.numeric(as.character(x)) #first convert each column into numeric if it is from factor
    x[is.na(x)] <- median(x, na.rm=TRUE) #convert the item with NA to median value from the column
    x #display the column
} #endfunc

df <- data.frame(apply(df,2,f)) # apply mean across dataframe by column (column = 2)

# replace appropriate columns
business.phx$numStarsback <- df$numStarsback
business.phx$numDays3back <- df$numDays3back
business.phx$numDays2back <- df$numDays2back
business.phx$numStars1back <- df$numStars1back
business.phx$numDays1back <- df$numDays1back
business.phx$numStars2back <- df$numStars2back
rm(df,f)

# -----make sure there's no zero sums in numeric variables-----

atnames <- names(Filter(is.numeric, business.phx)) # numeric variables only
x <- sort(colSums(business.phx[atnames])) # sort by sum
zeronames <- names(x[x==0]) # find names of columns with 0 sum  
business.phx <- business.phx[,!(names(business.phx) %in% zeronames)] #remove columns with zero sum
rm(x,zeronames,atnames)

# ---- convert factor variables into dummy variables (NOT INCL HOURS VARIABLES)----  

# ID your factor variables; pick your variables
atnames <- names(Filter(is.factor, business.phx)) 

for (i in 1:length(atnames)) { 
    idx <- unique(business.phx[atnames[i]]) #first create an index of factor levels
    idx <- idx[!(is.na(idx))] #remove NA as a potential factor name
    dummy <- matrix(NA, nrow = nrow(business.phx), ncol = length(idx)) #initialize a matrix to hold the dummy variables
    #evaluate each element in idx against the vector df$var1
    for (j in 1:length(idx)) { 
        dummy[,j] <- as.integer(business.phx[atnames[i]] == idx[j]) #create a vector of TRUE/FALSE observations; transform to  1/0 using as.integer
    } #endfor
    # create a temp data.frame from the matrix
    colnames(dummy) <- paste(atnames[i],idx,sep = ".")
    dummy <- as.data.frame(dummy) # convert matrix to data.frame
    business.phx <- cbind(business.phx,dummy)
    business.phx[atnames[i]] <- NULL #remove original extraneous variable
    rm(dummy,idx,i,j)
} #endfor

# make sure new variable names are syntactically correct
catnames <- make.names(colnames(business.phx[,601:632]), unique = TRUE, allow_ = TRUE) #make sure string names are syntactically correct
catnames <- gsub("..", ".", catnames, fixed = TRUE) # get rid of extra "."
catnames <- gsub("..", ".", catnames, fixed = TRUE) # get rid of extra "." (do it again)
names(business.phx)[601:632] <- catnames # rename a subset of data.frame variables with valid names

# replace NAs in dummy variables with 0
business.phx[,601:632] <- replace(business.phx[,601:632], is.na(business.phx[,601:632]), 0) 

rm(atnames,catnames)

#---post exploration: do more binning----

business.phx$review_countCLOSE <- 0
# adjust primary variable
business.phx$review_countCLOSE[business.phx$review_count<=2 | business.phx$review_count >=7 ] <- 1

business.phx$starsB <- 0
# adjust primary variable
business.phx$starsB[business.phx$stars<=1.5 | business.phx$stars >=4.5 ] <- 1

business.phx$laststarB <- 0
# adjust primary variable
business.phx$laststarB[business.phx$laststar==5] <- 1


###----EXPLORATORY DATA ANALYSIS ---

#----- descriptive statistics -----

prop.table(table(business.phx$open)) #proportion of open to closed businesses

max(review.phx$date) #first review date
min(review.phx$date) #last review date
summary(business.phx$review_count) # median number of reviews is 13, min is 3 

ux <- unique(business.phx$review_count)
ux[which.max(tabulate(match(business.phx$review_count, ux)))] # mode is 3
rm(ux,review.phx)

#----- correlation -----

#create data.frame with only numerics
cor.data <- Filter(is.numeric, business.phx)
cor.data$open <- as.numeric(business.phx$open) #adding business status to numeric data.frame

z = cor(cor.data)
z = z[,"open"]
z=as.data.frame(as.table(z))  #Turn into a 3-column table
z=z[order(-abs(z$Freq)),]    #Sort by highest correlation (whether +ve or -ve)
z <- z[z$Freq>=.08|z$Freq<=-.08,]  # reveal anything over .08 correlation coefficient

library(xtable) #create a nice printable table
options(xtable.floating = FALSE)

print(xtable(z, caption = NULL),
      caption.placement = "top",
      floating = TRUE, 
      latex.environments = "", 
      type = "html",
      file = "highcorr.html")

# checking variables against each other for correlation
z = cor(cor.data)
z[lower.tri(z,diag=TRUE)]=NA  #Prepare to drop duplicates and meaningless information
z=as.data.frame(as.table(z))  #Turn into a 3-column table
z=na.omit(z)  #Get rid of the junk we flagged above
z=z[order(-abs(z$Freq)),]    #Sort by highest correlation (whether +ve or -ve)

## Highly correlated variables...
z <- z[z$Freq>=.6|z$Freq<=-.6,]  # reveal anything over .6 correlation coefficient


print(xtable(z, caption = "Table 2.  Variables Correlating at >= 0.60"),
      caption.placement = "top",
      floating = TRUE, 
      latex.environments = "", 
      type = "html",
      file = "z2.html")


#----- mosaic plots -----

# use mosaic plots to visualize data cross-tabulated by business status
library(vcd)

# x <- names(business.phx[c(3,6:7,22:635)]) #breakout variables as needed
# 
# for (i in 1:length(x)) {
#     mosaicplot(business.phx[,x[i]] ~ business.phx$open, 
#                main= paste(x[i]," vs open"), shade=FALSE, 
#                color=TRUE, xlab= x[i], ylab="open")
# }#endfor

#-----sample of mosaic plots -----

plotnames <- c("attributes.Wheelchair.Accessible",
               "attributes.Waiter.Service",
               "attributes.Outdoor.Seating",
               "attributes.Alcohol.full_bar",
               "attributes.Takes.Reservations",
               "attributes.Good.For.lunch",
               "attributes.Smoking.yes",
               "numStars1back", 
               "attributes.Noise.Level.quiet")

png(filename = "mosaicsample.png",
    width = 480, 
    height = 480, 
    units = "px", 
    pointsize = 12,
    bg = "white", 
    res = NA, 
    family = "", 
    restoreConsole = TRUE,
    type = c("windows", "cairo", "cairo-png"))
par( mfrow = c( 3,3 ), mar = c(1,1,1,1) )
for (i in 1:length(plotnames)) {
    mosaicplot(business.phx[,plotnames[i]] ~ business.phx$open, 
               main= paste(plotnames[i]), shade=FALSE, 
               color=TRUE, xlab= plotnames[i], ylab="open")
}#endfor
dev.off()

rm(plotnames,i,z,cor.data)


###----MODEL BUILDING AND PREDICTION ---

# load library
library(caret)

#change as needed for different modeling subsets
modelset <- business.phx[,
                         c("business_id",
                           "open",
                           "attributes.Wheelchair.Accessible",
                           "attributes.Good.For.dinner",
                           "attributes.Waiter.Service",
                           "cat.Restaurants",
                           "attributes.Attire.casual",
                           "attributes.Outdoor.Seating",
                           "attributes.Take.out",
                           "attributes.Alcohol.full_bar",
                           "attributes.Good.For.Groups",
                           "attributes.Takes.Reservations",
                           "attributes.Parking.lot", 
                           "attributes.Good.For.lunch",
                           "attributes.Delivery",
                           "CreditCard",
                           
                           "attributes.Price.Range.1",
                           "attributes.Price.Range.4",
                           "attributes.Order.at.Counter",
                           "attributes.Ambience.trendy",
                           "attributes.Parking.street",
                           "attributes.Good.For.breakfast",
                           "cat.Bars",
                           "cat.Nightlife",
                           "cat.Ice.Cream.Frozen.Yogurt",
                           "cat.Coffee.Tea",
                           "cat.Bakeries",
                           "reviewbin.19.28.",
                           "reviewbin.91.1.51e.03.",
                           "reviewbin.3.4.",
                           "reviewbin.4.5.",
                           "reviewbin.7.10.",
                           "reviewbin.13.19.",
                           "attributes.BYOB.Corkage.yes_corkage",
                           "attributes.BYOB.Corkage.yes_free",
                           "attributes.Wi.Fi.paid",
                           "attributes.Smoking.no",
                           "attributes.Smoking.yes",
                           "attributes.Noise.Level.loud",
                           "attributes.Alcohol.beer_and_wine",
                           "attributes.Alcohol.none",
                           "attributes.Price.Range.2",
                           "numStarsback",
                           "numStars2back",
                           "numStars1back", 
                           "numDays3back",
                           "numDays2back",
                           "numDays1back",
                           "attributes.kids",
                           "attributes.BYOB.Corkage.no",
                           "attributes.Noise.Level.quiet",
                           "review_countCLOSE",
                           "starsB",
                           "laststarB",
                           "maxdatefinal",
                           "Diff2",
                           "Diff3")]

rm(business.phx)

#---test/tran/val datasets------

set.seed(101564) 
testIndex <- createDataPartition(y = modelset$open, p = .55, list = FALSE)
train <- modelset[ testIndex,]
test <- modelset[-testIndex,]
testIndex <- createDataPartition(y = test$open, p = .20, list = FALSE)
test <- test[ testIndex,]
val <- test[-testIndex,] 
rm(testIndex)

#remove business ID from training set
train$business_id <- NULL


#---- final regression model -----

# model1 <- everything from mosaic plots that looked like it had potential+created variables
# model2 <- cross-referenced all variables from model1 and added statistically significant interactions
# model3 <- removed statistically insignificant items from anova run on model2
# model4 <- removed statistically insignificant items from anova run on model3
# model5 <- removed statistically insignificant items from anova run on model4
# model6 <- removed statistically insignificant items from anova run on model5
# model7 <- final tweaking of model, extracting/inserting borderline significant material


fit.rg7 <- glm(open ~ attributes.kids +  
                   attributes.Good.For.dinner +
                   attributes.Waiter.Service +
                   attributes.Attire.casual +
                   attributes.Outdoor.Seating +
                   attributes.Price.Range.1 +
                   cat.Restaurants +
                   attributes.Parking.street +
                   attributes.Good.For.breakfast +
                   cat.Ice.Cream.Frozen.Yogurt +
                   cat.Coffee.Tea +
                   cat.Bakeries +
                   reviewbin.91.1.51e.03. +
                   reviewbin.7.10. +
                   reviewbin.13.19. +
                   attributes.Wi.Fi.paid +
                   numStarsback +
                   numDays3back +
                   numDays1back +
                   maxdatefinal +
                   attributes.Wheelchair.Accessible*attributes.Parking.lot +
                   attributes.Wheelchair.Accessible*reviewbin.3.4. +
                   attributes.Wheelchair.Accessible*numDays1back +
                   attributes.Wheelchair.Accessible*attributes.Noise.Level.quiet +
                   attributes.Wheelchair.Accessible*maxdatefinal +
                   attributes.Waiter.Service*attributes.Parking.street +
                   attributes.Waiter.Service*attributes.Good.For.breakfast +
                   attributes.Attire.casual*cat.Bakeries +
                   attributes.Attire.casual*numDays1back +
                   attributes.Attire.casual*review_countCLOSE +
                   attributes.Attire.casual*maxdatefinal +
                   attributes.Outdoor.Seating*reviewbin.19.28. +
                   attributes.Outdoor.Seating*maxdatefinal +
                   attributes.Take.out*reviewbin.4.5. +
                   attributes.Alcohol.full_bar*attributes.Order.at.Counter +
                   attributes.Alcohol.full_bar*reviewbin.19.28. +
                   attributes.Alcohol.full_bar*reviewbin.91.1.51e.03. +
                   attributes.Alcohol.full_bar*attributes.BYOB.Corkage.yes_free +
                   attributes.Good.For.Groups*attributes.Order.at.Counter +
                   attributes.Good.For.Groups*attributes.Noise.Level.loud +
                   attributes.Takes.Reservations*reviewbin.13.19. +
                   attributes.Parking.lot*attributes.Noise.Level.loud +
                   attributes.Parking.lot*maxdatefinal +
                   attributes.Good.For.lunch*maxdatefinal +
                   attributes.Price.Range.1*reviewbin.13.19. +
                   attributes.Delivery*reviewbin.7.10. +
                   cat.Bars*attributes.Smoking.no +
                   reviewbin.19.28.*starsB +
                   reviewbin.3.4.*CreditCard +
                   reviewbin.3.4.*maxdatefinal +
                   reviewbin.4.5.*maxdatefinal +     
                   reviewbin.7.10.*numDays2back +
                   reviewbin.13.19.*attributes.Smoking.no +
                   reviewbin.13.19.*CreditCard +
                   reviewbin.13.19.*starsB +
                   reviewbin.13.19.*maxdatefinal +
                   attributes.Alcohol.none*attributes.kids +
                   numStars2back*numDays3back +
                   numDays1back*Diff3 +
                   review_countCLOSE*maxdatefinal +
                   review_countCLOSE*Diff3 +
                   Diff3,
               data = train, family='binomial' (link='logit'))
summary(fit.rg7) # this model results in AIC= 1120
anova(fit.rg7,test="Chisq") # 15 warnings on ANOVA due to 0/1 - these are KNOWN and VALID


#----predict TEST set----

# make prediction on test set and adjust outcome  
predict.rg7 <- predict(fit.rg7,newdata=test,type='response')
predict.rg7 <- ifelse(predict.rg7 > 0.5,1,0)
test$open.rg7 <- as.numeric(test$open) #convert to numeric as separate variable and change binary to 0/1

t.cm <- confusionMatrix(predict.rg7,test$open.rg7)
t.cm


#---predict VAL set----
# make prediction on val set and adjust outcome  
predict.rg7v <- predict(fit.rg7,newdata=val,type='response')
predict.rg7v <- ifelse(predict.rg7v > 0.5,1,0)
val$open.rg7 <- as.numeric(val$open) #convert to numeric as separate variable and change binary to 0/1

v.cm <- confusionMatrix(predict.rg7v,val$open.rg7)
v.cm
#-------end val set ----

#calculating ROC curve and AUC for accuracy (AUC closest to 1 is preferred)

library(ROCR)
p <- predict.rg7
pr <- prediction(p, test$open) # pr <- prediction(p, val$open)
prf <- performance(pr, measure = "tpr", x.measure = "fpr")

png(filename = "ROC.png",
    width = 240, 
    height = 240, 
    units = "px", 
    pointsize = 12,
    bg = "white", 
    res = NA, 
    family = "", 
    restoreConsole = TRUE,
    type = c("windows", "cairo", "cairo-png"))
par( mfrow = c( 1,1 ), mar = c(1,1,1,1) )
plot(prf)
abline(a=0, b= 1)
dev.off()

auc <- performance(pr, measure = "auc")
auc <- auc@y.values[[1]]
auc # looking at about 80% predictive accurancy for test data; 80% on validation set


#### CLEAN UP MEMORY AT END OF SCRIPT
rm(list=ls())