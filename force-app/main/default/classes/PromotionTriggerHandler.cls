/*********************************************************************************************************************************
@ Class:          PromotionTriggerHandler
@ Version:        1.1
@ Author:         David Herrero (dherrero@ebay.com)
@ Purpose:        Handler Class for trigger Promotion copado)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 2022 / David Herrero / Created the class.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.01.2023 / David Herrero  / US-0013187 - Improve Promotion Dependencies trigger
----------------------------------------------------------------------------------------------------------------------------------
************************************************************************************************************************************************************************/
public with sharing class PromotionTriggerHandler {
/*
    public static String uatEnvironment;    
    static final String GET_PROMOTED_USER_STORIES='select id, copado__User_Story__c,copado__User_Story__r.copado__Developer__c  from copado__Promoted_User_Story__c  where copado__Promotion__c in :promotionsFromUAT';
    static final STring GET_METADATA_COMPONENTS='select id,copado__Metadata_API_Name__c,copado__User_Story__c, copado__User_Story__r.copado__Developer__c from copado__User_Story_Metadata__c where copado__User_Story__c in :userStories';
    static final String GET_METADATA_DEPENDENCIES='select id,copado__User_Story__c,copado__User_Story__r.name,copado__Metadata_API_Name__c,copado__User_Story__r.copado__Developer__c  from copado__user_story_metadata__c where copado__Metadata_API_Name__c in :metadataInPromotion and copado__User_Story__c not in:userStories AND copado__User_Story__r.copado__Org_Credential__r.name like \'%:uatEnvironment%\'';
    //static final String[] ComponentsToCheck = new String[]{'ApexClass','ApexTrigger','Layout','ApexPage','ApexTrigger','AuraDefinitionBundle','CustomObject','LightningComponentBundle','ExperienceBundle'};
    public static String[] componentsToCheck;
    static final String PROMOTION_SETTINGS='Dependencies';
    public static Boolean notifyOnlyWhenMergeConflict;
    static final String MERGE_CONFLICT_STATUS='Merge Conflict';
    static final String GET_DEVELOPERS_DETAILS='select id,name,email from User where isactive=true and id in :developerIds';
   
    //2023-01-31 Load configuration from custom metadata type
    private static void loadMetadataTypes(){
//
        if (Test.isRunningTest()){
            uatEnvironment='UAT';
            componentsToCheck= new String[]{'ApexClass','ApexTrigger','Layout','ApexPage','ApexTrigger','AuraDefinitionBundle','CustomObject','LightningComponentBundle','ExperienceBundle'};
            notifyOnlyWhenMergeConflict=false;
        }else{
           
        
        Promotion_Settings__mdt promotionSettings = Promotion_Settings__mdt.getInstance(PROMOTION_SETTINGS);
        if (promotionSettings==null){return;}
        uatEnvironment=promotionSettings.Origin_Sandbox__c;
        componentsToCheck=promotionSettings.Components_to_check__c.split(',');
        notifyOnlyWhenMergeConflict=promotionSettings.Notify_only_when_Merge_Conflict__c;
    }



    }    


    public static void checkDependenciesInPromotedComponents(List<copado__Promotion__c> promotions){

        Map<id,Copado__Environment__c> mapEnvironments = new Map<Id,Copado__Environment__c>([select id,name from Copado__Environment__c]);
        List<copado__Promotion__c> promotionsFromUAT = new List<copado__Promotion__c>();
        set<String>promotionOwners = new set<String>();
        if (componentsToCheck==null || notifyOnlyWhenMergeConflict == null || uatEnvironment==null){
            loadMetadataTypes();
        }
        
        for (copado__promotion__c p : promotions){
            if ( (notifyOnlyWhenMergeConflict && p.Copado__Status__c.equals(MERGE_CONFLICT_STATUS) || !notifyOnlyWhenMergeConflict)&&
             mapEnvironments.containskey(p.copado__Source_Environment__c) && 
             mapEnvironments.get(p.copado__Source_Environment__c).name.equals(uatEnvironment)){
                promotionsFromUAT.add(p);
                promotionOwners.add(p.LastModifiedById);

            }
        }

        if (promotionsFromUAT.isEmpty()){
            return;
        }
        // Get all stories included in the promotion

        copado__Promoted_User_Story__c[] promotedUserStories;
        ID[] userStories = new Id[1] ;
        copado__User_Story_Metadata__c[] metadataComponents;
        set<String> metadataInPromotion = new set<string>();
        map<id,String> mapUserStoryMetadata = new Map<id,string>();
        map<String,String>mapUserStoryDeveloper = new map<String,String>();
   
        promotedUserStories= Database.query(GET_PROMOTED_USER_STORIES);
        for (copado__Promoted_User_Story__c pus: promotedUserStories){
            userStories.add(pus.copado__user_story__c);
            mapUserStoryDeveloper.put(pus.copado__user_story__c,pus.copado__User_Story__r.copado__Developer__c);
        }

        // get all metadata deployed in each story
        if (userStories!=null){
            metadataComponents = Database.query(GET_METADATA_COMPONENTS );

            for (copado__user_story_metadata__c pusm: metadataComponents){
                if (ComponentsToCheck.contains( pusm.copado__Metadata_API_Name__c.left(pusm.copado__Metadata_API_Name__c.indexOf('.')))){
                    metadataInPromotion.add(pusm.copado__Metadata_API_Name__c);
                }
                

            }


        copado__User_Story_Metadata__c[] userStoriesWithDependencies = Database.query(GET_METADATA_DEPENDENCIES);
        map<String,String[]> metadatawithStories = new Map<String,String[]>();
        set<string> developerIds = new set<string>();

        for (copado__User_Story_Metadata__c usm : userStoriesWithDependencies){
            mapUserStoryDeveloper.put(usm.copado__user_story__c,usm.copado__user_story__r.copado__Developer__c);
            developerIds.add(usm.copado__user_story__r.copado__Developer__c);
            if (metadatawithStories.get(usm.copado__Metadata_API_Name__c)==null){
                metadatawithStories.put(usm.copado__Metadata_API_Name__c, new String[]{usm.copado__User_Story__r.name});
            }else{
                metadatawithStories.get(usm.copado__Metadata_API_Name__c).add(usm.copado__User_Story__r.name);
            }
        }
        System.debug('Dev- Ids:' + developerIds);
        List<User>listDevelopers = Database.query(GET_DEVELOPERS_DETAILS);
        Map<id,User> mapUsers = new Map<id,User>(listDevelopers); //initizlize map with content of listDevelopers
        set<String>destinations = new set<String>(); //destination eails
        set<String>developerEmails = new set<String>();
        for (User u : listDevelopers){
            developerEmails.add(u.Email);
        }
        if (!metadatawithStories.isEmpty()){

            String bodyMessage='';
            for (String metaCompo : metadatawithStories.keySet()){
                bodyMessage+='Metadata: ' +metaCompo + '\r User stories (' +uatEnvironment + '): ';
                for (String story : metadatawithStories.get(metaCompo)){
                        bodyMessage += story + ',';

                }
                bodyMessage=bodyMessage.left(bodymessage.length()-1);
                bodyMessage+='\r **************** \r';
            }



        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
		//String[] sendingTo = new String[]{'dherrero@ebay.com'};
        String[] sendingTo = new String[]{UserInfo.getUserEmail()};

		semail.setToAddresses(sendingTo);
        semail.setCcAddresses(new List<String>(developerEmails));
		
		semail.setSubject(Label.PromotionTH_Warning);
		semail.setPlainTextBody(bodyMessage);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
        }

        System.debug(userStoriesWithDependencies);

        }
        


    }
*/
// definitions
public static String originCredential;  
public static List<String> componentsToCheck;
public static Boolean notifyOnlyWhenMergeConflict;
static final String PROMOTION_SETTINGS='Dependencies';
static final String MERGE_CONFLICT_STATUS='Merge Conflict';




//SOQL QUERIES
static final String GET_CREDENTIALS='select id,name from copado__Org__c';
static final String GET_PROMOTED_USER_STORIES='select copado__User_Story__c,copado__User_Story__r.name  from copado__Promoted_User_Story__c  where copado__Promotion__c in :lpromotions';
static final STring GET_METADATA_COMPONENTS='select id,copado__Metadata_API_Name__c,copado__User_Story__c,copado__User_Story__r.name from copado__User_Story_Metadata__c where copado__User_Story__c in :luserStories';
static final String GET_METADATA_DEPENDENCIES='select id,copado__User_Story__c,copado__User_Story__r.name,copado__Metadata_API_Name__c  from copado__user_story_metadata__c where copado__Metadata_API_Name__c in :lStringDeployedMetadata and copado__User_Story__c not in:luserStories AND copado__User_Story__r.copado__Org_Credential__r.name =:originCredential';
static final String GET_ALL_USER_STORIES='select id,name,Copado__Developer__c from Copado__user_Story__c where id in :setIdsUserStories';
final static String GET_USER_EMAILS='select id,Email from User where isactive=true and id in : ownersAndDevelopers';



private static void loadMetadataTypes()
{         
         if (Test.isRunningTest()){
            originCredential='UAT';
    componentsToCheck= new String[]{'ApexClass','ApexTrigger','Layout','ApexPage','ApexTrigger','AuraDefinitionBundle','CustomObject','LightningComponentBundle','ExperienceBundle'};
    notifyOnlyWhenMergeConflict=false;
}else  {
   

Promotion_Settings__mdt promotionSettings = Promotion_Settings__mdt.getInstance(PROMOTION_SETTINGS);
if (promotionSettings==null){return;}
originCredential=promotionSettings.Origin_Sandbox__c;
componentsToCheck=promotionSettings.Components_to_check__c.split(',');
notifyOnlyWhenMergeConflict=promotionSettings.Notify_only_when_Merge_Conflict__c;
}
    
        } 
public static void checkDependenciesInPromotedComponents(List<copado__Promotion__c> promotions){

    loadMetadataTypes();
    List<copado__promotion__c> lpromotions = new List<copado__Promotion__c>();
    Map<Id,String> mapCredential= new Map<Id,String>();
    List<ID>luserStories =new List<ID>();
    List<copado__User_Story_Metadata__c>ldeployedMetadata = new List<copado__User_Story_Metadata__c>();
    List<String>lStringDeployedMetadata = new List<String>();

    for (Copado__Org__c e : Database.query(GET_CREDENTIALS)){
        mapCredential.put(e.id,e.name);
    }
    for (Copado__promotion__c p : promotions){
        System.debug(p.copado__status__c);
        System.debug('notifyOnlyWhenMergeConflict' + notifyOnlyWhenMergeConflict);
        System.debug('copado__Source_Org_Credential__c=>' + p.copado__Source_Org_Credential__c);
        System.debug('originCredential' + originCredential);
        if ( (notifyOnlyWhenMergeConflict && p.Copado__Status__c.equals(MERGE_CONFLICT_STATUS) || !notifyOnlyWhenMergeConflict)&&
        mapCredential.containskey(p.copado__Source_Org_Credential__c) && 
        mapCredential.get(p.copado__Source_Org_Credential__c).equals(originCredential)){
            lpromotions.add(p);

    }
    }
    if (lpromotions.isEmpty()){return;}

    //retrieve user stories of the promotion
    for (Copado__Promoted_User_Story__c pus : Database.query(GET_PROMOTED_USER_STORIES)){
        luserStories.add(pus.copado__User_Story__c);

    }
    map<string,string[]>mapPromotedMetadataListUserStories  = new map<string,string[]>();
    set<string>setIdsUserStories = new Set<String>();
    
   
    //retrieve metada included in the user stories
    for (Copado__User_story_Metadata__c usm : Database.query(GET_METADATA_COMPONENTS)){
        
        if (!ComponentsToCheck.contains( usm.copado__Metadata_API_Name__c.left(usm.copado__Metadata_API_Name__c.indexOf('.')))){
            continue;
        }
         ldeployedMetadata.add(usm);
        lStringDeployedMetadata.add(usm.copado__Metadata_API_Name__c);
        if (mapPromotedMetadataListUserStories.containsKey(usm.copado__Metadata_API_Name__c)){
            mapPromotedMetadataListUserStories.get(usm.copado__Metadata_API_Name__c).add(usm.copado__user_story__r.name);
        }else{
            mapPromotedMetadataListUserStories.put(usm.copado__Metadata_API_Name__c, new List<String>{usm.copado__user_story__r.name});

        }
    }
   
    
    for (String key : mapPromotedMetadataListUserStories.keySet()){
        setIdsUserStories.addAll(mapPromotedMetadataListUserStories.get(key));
    }
    //retrieve metadata from All user stories in UAT that are not part of the deployment
 
    Map<String,String[]> mapUserStoryMetadata = new Map<String,String[]>();

   
    for (COPAdo__User_story_metadata__c cusm : Database.query(GET_METADATA_DEPENDENCIES)){
        if (mapUserStoryMetadata.containsKey(cusm.copado__Metadata_API_Name__c)){
            mapUserStoryMetadata.get(cusm.copado__Metadata_API_Name__c).add(cusm.copado__user_story__r.name);
        }else{
            mapUserStoryMetadata.put(cusm.copado__Metadata_API_Name__c,new List<String>{cusm.copado__user_story__r.name});
        }
    }   

    for (String key : mapUserStoryMetadata.keySet()){
        setIdsUserStories.addAll(mapUserStoryMetadata.get(key));
    }
    Map<Id,Copado__user_story__c> mapIdUserStories= new Map<Id,Copado__User_Story__c>((List<Copado__User_Story__c>)Database.query(GET_ALL_USER_STORIES));
    String bodyMessage ='';
   String promotedStories='';
   set<string> storiesDevelopers = new Set<String>();

        for (String metadataAPIName : mapUserStoryMetadata.keySet()){
            //Metadata
            //Promoted Stories
           if (mapPromotedMetadataListUserStories.containsKey(metadataAPIName)){
            promotedStories=String.join(mapPromotedMetadataListUserStories.get(metadataAPIName),',');
           }
           bodyMessage+=metadataAPIName + ' is promoted in following user stories : ' + promotedStories;
           bodyMessage+='\r and is also part of following stories remaining in ' + originCredential + '\t:';
           bodyMessage+=String.join(mapUserStoryMetadata.get(metadataAPIName),',');
           bodyMessage+='\r *************************************** \r';

        }


        if (!bodyMessage.equals('')){
            //Get Promotion Owner Emails
            set<String>ownerEmails = new set<String>();
            Set<String>developerEmails = new Set<String>();
            set<string>ownerIds = new set <String>();
            set<string>developerIds = new set <String>();
            for (Copado__Promotion__c p : lpromotions){
                ownerIds.add(p.LastModifiedById);
            }
            for (Copado__user_story__c cus: mapIdUserStories.values()){
                developerIds.add(cus.copado__Developer__c);

            }
            set<String>ownersAndDevelopers = new Set<String>();
            ownersAndDevelopers.addAll(ownerIds);
            ownersAndDevelopers.addAll(developerIds);
            
            Map<Id,User> mapUserEmail = new Map<Id,User>((List<User>)Database.query(GET_USER_EMAILS));
            for (ID userId: mapUserEmail.keySet()){
                if (ownerIds.contains(userId)){
                    ownerEmails.add(mapUserEmail.get(userId).Email);
                }else if (developerIds.contains(userId)){
                    developerEmails.add(mapUserEmail.get(userId).Email);
                }
            }
            //remove duplicates in developeremails
            developerEmails.removeAll(ownerEmails);


            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            //String[] sendingTo = new String[]{'dherrero@ebay.com'};
            String[] sendingTo = new List<String>();
            sendingTo.addAll(ownerEmails);
    
            semail.setToAddresses(sendingTo);
            //Send to developers just if is not empty
            if(!developerEmails.isEmpty()){
                semail.setCcAddresses(new List<String>(developerEmails));
            }
            
            
            semail.setSubject(Label.PromotionTH_Warning);
            semail.setPlainTextBody(bodyMessage);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
            }
            



        }



   

}