/*********************************************************************************************************************************
@ Class:          EBH_TrainingMaterialsController
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Controller for VF page: EBH_TrainingMaterials - This is without sharing - public  
                  EPH-2759 : Training Material
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.06.2017 / JOY MONDOL / Created the class.
*********************************************************************************************************************************/
public without sharing class EBH_TrainingMaterialsController {

    public List<EBH_TrainingMaterial__c> Materials { get; set; }    //training materials to display as links
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_TrainingMaterialsController
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        to get the Training Material records
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.06.2017 / JOY MONDOL (jmondol@deloitte.co.uk) / Created the  Method.
    *****************************************************************************************************************************/
    public EBH_TrainingMaterialsController() {
        
        //fetch all the training materials where FILE URL or URL is present and sorted by Sequence
        Materials = Database.query(EBH_ConstantsUtility.TRAINING_QUERY);
        List<String> SA_Profiles = new List<STring> {'System Administrator','System Administrator - Limited Privileges'};
        set<id> AdminProfiles = new set <id>();
        for (Profile p : [select id from Profile where name in :SA_Profiles]){
            AdminProfiles.add(p.id);
        }
         
        if (!AdminProfiles.contains(UserInfo.getProfileId() )){
            for (Integer i=0;i<Materials.size();i++){
                if (Materials.get(i).Admins_only__c){
                    Materials.remove(i);
                }
                
            }
        }
    }
}