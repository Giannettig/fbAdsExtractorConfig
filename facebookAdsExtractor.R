############################################################
#                       INSTALLATION                       #
############################################################

# first need to install the devtools package if it isn't already installed
install.packages("devtools")
# load the library
library(devtools)

# this package relies on another github package 
# for aws request signature generation
devtools::install_github("cloudyr/aws.signature")

# install the sapi client package
devtools::install_github("keboola/sapi-r-client")
library('keboola.sapi.r.client')

# load the library (dependencies will be loaded automatically)
library(keboola.sapi.r.client)


############################################################
# PUT HERE NECESSARY INFORMATION FOR SETTING THE EXTRACTOR #
############################################################

##USER VARIABLES
apikey <- "YOUR-API-KEY-HERE"
configName <- "PROJECT-NAME"

##SAMPLE FB EXTRACTOR CONFIG

#For API v2.6

fbConfig<-
'"endpoint","params","dataType","dataField","recursionParams","rowId"
"act_<ad_account_number>/campaigns","{""fields"":""id,name,account_id""}","campaigns","data","","1"
"act_<ad_account_number>/adsets","{""fields"":""id,name""}","adsets","data","","2"
"act_<ad_account_number>/ads","{""fields"":""id,name""}","ads","data","","3"
"{3:id}/insights","{""fields"":""ad_id,impressions,actions,clicks,spend"",""date_preset"": ""last_7_days"",""time_increment"":""1""}","ads_insights","data","","4"'

##CONFIG DOCUMENTATION - CREDIT Marcus Wong, Keboola

# replace the account numbers on each row in the endpoint to the corresponding account number that you are trying to extract from
# on the first run, the extractor will create a new metadata bucket and table, do not delete it
# 
# endpoints - pretty self-explanatory
# fields - you can add there all the fields you want to download from API, list of fields can be found in documentation
# date_preset - describes for how long in history you want to download data
# time_increment - segmentation by days - can 1 to 90 - 1 means 1 row per day (**NOTE** THIS does not mean incremental writing into SAPI!) 
# by using {2:id} you can actually use parameters downloaded in other queries. The integer is ID of the row (rowID), then there is a field name. This means that for every id from query on row 2 download data.
# action_breakdowns - list of parameters on which you want to do group by 
# 
# **NOTE** FB Ads API apparently has a "feature" of not sending empty data. So in case you have no records for a given day it means there is nothing to show. I know, it sucks.
# For upgrading from older API to the new, you have to rename some of the endpoints. Very simple help is like this:
#   Change /adcampaign_groups to /campaigns
# Change /adcampaigns to /adsets
# Change /adgroups to /ads
# In the write path, change campaign_group_status, campaign_status, adgroup_status tostatus
# Source: https://developers.facebook.com/docs/apps/changelog
# Also, do not forget to change field names as described here: https://developers.facebook.com/docs/marketing-api/reference/v2.5_rename/v2.5 
# 

############################################################
#                      RUN THE SCRIPT                      #
############################################################

## GLOBAL VARIABLES - DO NOT TOUCH

fbConfig<-read.csv(textConnection(fbConfig))

# create client
client <- SapiClient$new(token = apikey)

# verify the token
tokenDetails <- client$verifyToken()

# create the sys bucket for the extractor
bucket <- client$createBucket("ex-fb-ads","sys","Facebook Ads Extractor",backend='snowflake')

# create the config table in the fb ads bucket
table <- client$saveTable(fbConfig, bucket$id, configName,options=list(primaryKey = "rowId"))

# now we need to register the extractor

## A Tady jsem v prdeli protože to nejde.


#send this link to a client to authorize:
clientLink <-
  paste(
    "https://syrup.keboola.com/ex-fb-ads/oauth?token=",
    apikey,
    "&config=",
    tableName,
    sep = ""
  )

print(clientLink)