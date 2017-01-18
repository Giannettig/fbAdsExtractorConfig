
############################################################
# PUT HERE NECESSARY INFORMATION FOR SETTING THE EXTRACTOR #
############################################################

##USER VARIABLES
apikey <- "YOUR-API-KEY-HERE"
configName <- "PROJECT-NAME"

#to make the config work you will also need the “Ad Account Number” 
#(NOT the business manager id)  which your client should be able to provide from https://business.facebook.com 

adAccountNumber<-"the_account number given by the client"

##SAMPLE FB EXTRACTOR CONFIG

#For API v2.6

fbConfig<-
paste('"endpoint","params","dataType","dataField","recursionParams","rowId"
"act_',adAccountNumber,'/campaigns","{""fields"":""id,name,account_id""}","campaigns","data","","1"
"act_',adAccountNumber,'/adsets","{""fields"":""id,name""}","adsets","data","","2"
"act_',adAccountNumber,'/ads","{""fields"":""id,name""}","ads","data","","3"
"{3:id}/insights","{""fields"":""ad_id,impressions,actions,clicks,spend"",""date_preset"": ""last_7_days"",""time_increment"":""1""}","ads_insights","data","","4"', sep='')

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

#' registerComponent
#' Registers a custom component in keboola without UI
#' @param apikey X-StorageApi-Token
#' @param bucket The bucket where the configuration table is located
#' @param configName The name of the configuration table
#' @param kbcConfigId The id of the registered component. 
#' A list of all components in KBC is here: https://connection.keboola.com/v2/storage/
#' @example registerComponent(apikey,configName,'keboola.ex-facebook-ads')

registerComponent<-function(apikey,configName,kbcConfigId){

  endpoint<-paste("https://connection.keboola.com/v2/storage/components/",kbcConfigId,"/configs",sep="")
  
  call <- POST(endpoint,body=list(configurationId=configName,name=paste("Facebook Ads Extractor",configName)),add_headers('X-StorageApi-Token'=apikey))
  
  results<-if(!call$status_code==201) {
    stop(paste("API Call failed. status:",content(call)$error, sep=" "),call.=TRUE)
  }

  }

registerComponent(apikey,configName,'keboola.ex-facebook-ads')
                              
#send this link to a client to authorize:
clientLink <-
  paste(
    "https://syrup.keboola.com/ex-fb-ads/oauth?token=",
    apikey,
    "&config=",
    configName,
    sep = ""
  )

print(clientLink)