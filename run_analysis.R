###----
# Project "3. Getting and Cleaning Data" / John Hopkins University / Coursera
# Author: Roman Kornyliuk
###----

# This R script "run_analysis.R" does the following:
# - Merges the training and the test sets to create one data set.
# - Extracts only the measurements on the mean and standard deviation for each measurement.
# - Uses descriptive activity names to name the activities in the data set.
# - Appropriately labels the data set with descriptive variable names.
# - From the data set in step 4, creates a second, independent tidy data set 
#with the average of each variable for each activity and each subject.

###----
# Load Data
###----

pack <- c("reshape2", "data.table", "dplyr", "ggplot2")
sapply(pack, require, character.only=TRUE, quietly=TRUE)
path <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(path, "dataFiles.zip"))
unzip(zipfile = "dataFiles.zip")

###----
# Load features and labels
###----

a_labels <- fread(file.path(path, "UCI HAR Dataset/activity_labels.txt")
                        , col.names = c("classLabels", "activityName"))
features <- fread(file.path(path, "UCI HAR Dataset/features.txt")
                  , col.names = c("index", "featureNames"))
features_chosen <- grep("(mean|std)\\(\\)", features[, featureNames])
measurements <- features[features_chosen, featureNames]
measurements <- gsub('[()]', '', measurements)

###----
# Load training data
###----

train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, features_chosen, with = FALSE]
data.table::setnames(train, colnames(train), measurements)
trainActivities <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt")
                       , col.names = c("Activity"))
trainSubjects <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt")
                       , col.names = c("SubjectNum"))
train <- cbind(trainSubjects, trainActivities, train)

###----
# Load testing data
###----

test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, features_chosen, with = FALSE]
data.table::setnames(test, colnames(test), measurements)
testActivities <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt")
                        , col.names = c("Activity"))
testSubjects <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt")
                      , col.names = c("SubjectNum"))
test <- cbind(testSubjects, testActivities, test)

###----
# United dataset
###----
combined <- rbind(train, test)

# Convert classLabels to activityName basically. More explicit. 
combined[["Activity"]] <- factor(combined[, Activity]
                              , levels = a_labels[["classLabels"]]
                              , labels = a_labels[["activityName"]])

combined[["SubjectNum"]] <- as.factor(combined[, SubjectNum])
combined <- reshape2::melt(data = combined, id = c("SubjectNum", "Activity"))
combined <- reshape2::dcast(data = combined, SubjectNum + Activity ~ variable, fun.aggregate = mean)

data.table::fwrite(x = combined, file = "tidy_data_set.txt", quote = FALSE)



