############## FBO XML FILE DATA CLEANING AND PROCESSING ###################
#This script imports an FBO XML file and adds a few columns
#It includes search agents to identify potentially relevant search results for solicitation review project
#It delivers a data frame of these potential results
#It creates a data frame of the modifications to the original solicitations (these are known as "amendments" on FBO)
#It saves the data frames into a folder and writes them to Excel files. I chose Excel over CSV because some of the cells exceed the character limit. Excel files will truncate, whereas CSV files will write the characters above the limit into new cells.

#REMEMBER TO CHANGE:
#import XML file
#save file for df
#save file for df_filtered data frame
#write file for df_filtered Excel file
#save file for modifications data frame
#write file for modifications Excel file 

###############################################################

require("XML")
require("dplyr")
require("xlsx")
setwd("/Users/ascodel/Google Drive/SFO Group Files/FEMP EEPP/Solicitation Review/Data")

######################################################
###### IMPORT FULL FY XML FILE AND PARSE ##############

#Set up data frame with raw solicitations
xml_file = xmlParse("FBO_XML_files/FBO_FY2016.xml")
root = xmlRoot(xml_file)
df = xmlToDataFrame(root, colClasses = NULL)
posts = xmlSize(root)

#Make column for posting type
for (i in 1:posts) {
  df$Type[i] = xmlName(root[[i]])
}

#Identify fiscal year quarter for date of posting
df$DATE <- as.Date(df$DATE, "%m%d%Y")
df$CYquarter <- quarters(df$DATE)
df$FYquarter <- 0
df$FYquarter[df$CYquarter=="Q4"] <-"Q1"
df$FYquarter[df$CYquarter=="Q1"] <-"Q2"
df$FYquarter[df$CYquarter=="Q2"] <-"Q3"
df$FYquarter[df$CYquarter=="Q3"] <-"Q4"

load("Data_Frames/FY16/FY16SOLNUM.Rda") 
df = subset(df, !SOLNBR %in%FY16SOLNUM) #only keep rows that aren't already in our dataset

########################################################
############# APPLY SEARCH AGENTS ######################

#Create data frame for filtered results
columns = colnames(df)
number_columns = ncol(df)
df_filtered = data.frame(matrix(ncol = number_columns, nrow=0)) #creates blank data frame to ultimately hold filtered results
colnames(df_filtered) <-paste(columns) #assign dataset column names to blank dataframe

#Create individual data frame for results of each search agent
sa1 = filter(df, grepl('hvac | chiller | water heater | ventilation fan', DESC, ignore.case = TRUE) | grepl('hvac | chiller | water heater | ventilation fan', SUBJECT, ignore.case = TRUE))
sa1$PRODCAT = "Heating and Cooling"
sa1$searchterm = 1

sa2 = filter(df, (CLASSCOD=='R' | CLASSCOD=='W' | CLASSCOD=='Y' | CLASSCOD=='Z' | CLASSCOD=='41' | CLASSCOD=='45' | CLASSCOD=='J' | CLASSCOD=='C') & (NAICS=='236220' | NAICS== '238220' | NAICS=='541310' | NAICS=='811310' | NAICS=="541330") & (grepl('heating | cooling | boiler | A/C | air conditioner | air conditioning | furnace | heat pump', DESC, ignore.case = TRUE) | grepl('heating | cooling | boiler | A/C | air conditioner | air conditioning | furnace | heat pump',SUBJECT, ignore.case=TRUE)))
sa2$PRODCAT = "Heating and Cooling"
sa2$searchterm = 2

sa3 = filter(df, NAICS=="236210")
sa3$PRODCAT = "Heating and Cooling"
sa3$searchterm = 3

sa4 = filter(df, (CLASSCOD=='59' | CLASSCOD=='70') & (NAICS!="511210") & (grepl('computer | laptop | workstation | monitor | uninterruptible power supply | uninterruptible power supplies', DESC, ignore.case = TRUE) | grepl('computer | laptop | workstation | monitor | uninterruptible power supply | uninterruptible power supplies | server', SUBJECT, ignore.case=TRUE)))
sa4$PRODCAT = "IT & Electronics"
sa4$searchterm = 4

sa5 = filter(df, grepl('uninterruptible power', DESC, ignore.case = TRUE) | grepl('uninterruptible power', SUBJECT, ignore.case=TRUE))
sa5$PRODCAT = "IT & Electronics"
sa5$searchterm = 5

sa6 = filter(df, (CLASSCOD=='70'  | CLASSCOD=='74' | CLASSCOD=='75' | CLASSCOD=='W' | CLASSCOD=='J') & (NAICS!="511210") & !grepl('3D printer', DESC, ignore.case = TRUE) & !grepl('3D printer', SUBJECT, ignore.case=TRUE) & (grepl('copier | scanner | printer | mail machine', DESC, ignore.case = TRUE) | grepl('copier | scanner | printer | mail machine', SUBJECT, ignore.case = TRUE)))
sa6$PRODCAT = "IT & Electronics"
sa6$searchterm = 6

sa7 = filter(df, (CLASSCOD=='58' | CLASSCOD=='70' | CLASSCOD=='74') & (NAICS!="511210") & (grepl('TV', DESC, ignore.case = TRUE) | grepl('TV', SUBJECT, ignore.case = TRUE)))
sa7$PRODCAT = "IT & Electronics"
sa7$searchterm = 7

sa8 = filter(df, CLASSCOD=='58' & grepl('phone', SUBJECT, ignore.case = TRUE) & grepl('VOIP | voice over IP | phone system | telephone system', SUBJECT, ignore.case = TRUE))
sa8$PRODCAT = "IT & Electronics"
sa8$searchterm = 8

sa9 = filter(df, (CLASSCOD=='62' | CLASSCOD=='Y' | CLASSCOD=='Z') & (grepl('light | lamp', DESC, ignore.case = TRUE) | grepl('light | lamp', SUBJECT, ignore.case = TRUE)))
sa9$PRODCAT = "Lighting"
sa9$searchterm = 9

sa10 = filter(df, CLASSCOD=='73' & (grepl('food service | dishwasher | fryer | hot food holding cabinet | griddle | ice machine | oven | steamer | refrigerator | freezer', DESC, ignore.case = TRUE) | grepl('food service | dishwasher | fryer | hot food holding cabinet | griddle | ice machine | oven | steamer | refrigerator | freezer', SUBJECT, ignore.case = TRUE)))
sa10$PRODCAT = "Commercial Food Service Equipment"
sa10$searchterm = 10

sa11 = filter(df, grepl('cafeteria service | vending machine | kitchen | washing machine', DESC, ignore.case = TRUE) | grepl('cafeteria service | vending machine | kitchen | washing machine',SUBJECT, ignore.case = TRUE))
sa11$PRODCAT = "Commercial Food Service Equipment"
sa11$searchterm = 11

sa12 = filter(df, (CLASSCOD=='41' | CLASSCOD=='72' | CLASSCOD=='73') & (grepl('refrigerator | freezer | dehumidifier', DESC, ignore.case = TRUE) | grepl('refrigerator | freezer | dehumidifier', SUBJECT, ignore.case = TRUE)))
sa12$PRODCAT = "Appliances"
sa12$searchterm = 12

sa13 = filter(df, (CLASSCOD=='35' | CLASSCOD== '72' | CLASSCOD=='W') & (grepl('washer', DESC, ignore.case = TRUE) | grepl('washer', SUBJECT, ignore.case=TRUE)))
sa13$PRODCAT = "Appliances"
sa13$searchterm = 13


#Create a data frame with the unique records from each search agent result 
sol_numbers = df_filtered$SOLNBR #all the solicitation #s we already have in the filtered dataset

sa1_trim <- subset(sa1, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa1_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa2_trim <- subset(sa2, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa2_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa3_trim <- subset(sa3, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa3_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa4_trim <- subset(sa4, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa4_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa5_trim <- subset(sa5, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa5_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa6_trim <- subset(sa6, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa6_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa7_trim <- subset(sa7, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa7_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa8_trim <- subset(sa8, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa8_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa9_trim <- subset(sa9, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa9_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa10_trim <- subset(sa10, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa10_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa11_trim <- subset(sa11, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa11_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR 

sa12_trim <- subset(sa12, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa12_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR

sa13_trim <- subset(sa13, !SOLNBR %in%sol_numbers) #solnumbers needs to continually update
df_filtered = rbind(df_filtered,sa13_trim) #add trimmed results to dataframe
sol_numbers = df_filtered$SOLNBR

df_filtered = filter(df_filtered, (NAICS != "334515" | NAICS != "335931" | NAICS != "611420" | NAICS != "541380" |  NAICS != "334417" | NAICS != "334290" |NAICS != "336320" | NAICS != "423610" | NAICS != "561720" | NAICS != "541511" | NAICS != "334516" | NAICS != "561790" | NAICS != "334511" | NAICS != "336413" | NAICS != "336611" | NAICS != "423430" | NAICS != "237310" | NAICS != "561730" | NAICS != "623220" | NAICS != "721110"))

df_filtered$CHANGES[df_filtered$CHANGES !="" & df_filtered$CHANGES !="N/A"] <- "See Modifications" #This is to reduce the size of the export file.

#FY16SOLNUM = sol_numbers
FY16SOLNUM <- c(FY16SOLNUM, sol_numbers)
save(FY16SOLNUM, file = "Data_Frames/FY16/FY16SOLNUM.Rda") #add new sol numbers

##NEW STUFF NEXT TWO ROWS:
#Reorder columns so that they always come out the same
df_filtered$Week <- 0
df_filtered <- df_filtered[,c("DATE","Week","AGENCY","OFFICE","LOCATION","ZIP","CLASSCOD","NAICS","OFFADD","SUBJECT","SOLNBR","RESPDATE","ARCHDATE", "CONTACT","DESC",	"LINK","SETASIDE","RECOVERY_ACT",	"DOCUMENT_PACKAGES","POPCOUNTRY","POPZIP","POPADDRESS","CHANGES","EMAIL",	"AWDNBR",	"AWDAMT",	"AWDDATE",	"AWARDEE","STAUTH",	"LINENBR","MODNBR","FOJA","DONBR","Type",	"CYquarter","FYquarter","PRODCAT","searchterm")]		
df_filtered$Relevant <- 0

save(df_filtered, file = "Data_Frames/FY16/new.Rda")

write.xlsx(df_filtered, "FBO_Excel_files/new.xlsx")



