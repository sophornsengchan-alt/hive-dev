/*********************************************************************************************************************************
@ Class:          EBH_CampaignApprovalSettingsController
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        EPH-3184: Controller Class for EBH_ContractApprovalSettings page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 27.09.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_CampaignApprovalSettingsController {
    
    /*global variables/properties*/    
    public Id      RemoveId  { get; set; } //hierarchy id of the selected/removed row
    public String  Site      { get; set; } //site of the selected section
    public Boolean EditView  { get; set; } //edit mode flag
    
    public String  HRFINANCE { get; set; } //Finance string value for finance hierarchy
    
    public Map<String, RecordType>                             HierarchyTypes               { get; set; } //record types
    public Map<String, EBH_CampaignApprovalMatrix__c>          ApprovalMatrices             { get; set; } //master matrix
    public Map<String, List<EBH_CampaignApprovalGroup__c>> CampaignApprovalHierarchy     { get; set; } //finance hierarchy
    
    /*private variables/properties*/    
    private List<Id> RemoveIds = new List<Id>();
    
    /*****************************************************************************************************************************
    @ Constructor:    EBH_ContractApprovalSettingsController
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Initialises the class for controller instance.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public EBH_CampaignApprovalSettingsController() { 
    
        initiate();
    }
    
    /*****************************************************************************************************************************
    @ Method:         initiate
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Initialises the class.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void initiate() {
        
        List<EBH_CampaignApprovalMatrix__c> matrices; //approval matrices
        
        //initialise the master data structures for the page
        HierarchyTypes               = new Map<String, RecordType>();        
        ApprovalMatrices             = new Map<String, EBH_CampaignApprovalMatrix__c>();
        CampaignApprovalHierarchy     = new Map<String, List<EBH_CampaignApprovalGroup__c>>();
                
       // try {
            
            //fetch the record types
            matrices = Database.query(EBH_ConstantsUtility.CAMS_MTRXPQUERY);
        //} catch(Exception ex) {
           // EBH_ApexLogger.logError(new List<Exception> { ex }, 
             //                       EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M4);
       // }
        
        
        //loop through the matrix and the hierarchy per site to populate the loacl hierarchy datastructure
        for(EBH_CampaignApprovalMatrix__c am : matrices) {
            
            ApprovalMatrices.put(am.EBH_Site__c, am);
            
            List<EBH_CampaignApprovalGroup__c> finAhs = new List<EBH_CampaignApprovalGroup__c>();
            List<EBH_CampaignApprovalGroup__c> conAhs = new List<EBH_CampaignApprovalGroup__c>();
            
            //loop through the hierarchy
            for(EBH_CampaignApprovalGroup__c ah : am.EBH_CampaignApprovalGroup__r) {
                    finAhs.add(ah);
            }
            
            //populate the hierarchy maps for finance anf control tracks
            CampaignApprovalHierarchy.put(am.EBH_Site__c, finAhs);
           
        }
    }
        
    /*****************************************************************************************************************************
    @ Method:         createNewMatrices
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Creates new approval matrix for the sites that does not exits for the time.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void createNewMatrices() {
        
        List<EBH_CampaignApprovalMatrix__c> newMatrices = new List<EBH_CampaignApprovalMatrix__c>();
        List<Group> newGroups = new List<Group>();
        Set<String> crsGroups;
        Map<String, ID> sitePublicGroupMap = new Map<String,ID>(); //to store Site as Key and Id of the public group as value
        Map<String, String> campRequestSites  = new Map<String,String>();
        Map<String, String> sitePublicGroupss  = new Map<String,String>();
        
        //to get the custom settings data - public group developer name as key and Site value
        for( EBH_CampaignRequestSiteGroup__c request : EBH_CampaignRequestSiteGroup__c.getAll().values()){
        
             campRequestSites.put(request.EBH_PublicGroup__c, request.Name);
             sitePublicGroupss.put(request.Name, request.EBH_PublicGroup__c);
        }
        crsGroups = campRequestSites.keyset();
        //Key will be Site and value will be group ID required for creating group members
        for(Group grp :Database.query(EBH_constantsUtility.CASC_GRPMEMS)){
            sitePublicGroupMap.put( campRequestSites.get(grp.DeveloperName), grp.Id );
        }   
        //loop through the site picklist metadata and check if apptoval matrix esists
        for(SelectOption st : getSites()) {
            
            if(!ApprovalMatrices.containsKey(st.getValue())) {
                newMatrices.add(new EBH_CampaignApprovalMatrix__c(EBH_Site__c = st.getValue()));
            }
            if(!sitePublicGroupMap.containsKey( st.getValue() )){
                 newGroups.add( new Group( Name= sitePublicGroupss.get(st.getValue() ) ) );
            }
        }
        if( !newGroups.isEmpty()) {    
            try {
                //insert the new matrices
                Database.insert(newGroups);
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                        EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M3);
            }
        }
        
        //if not every site has got approval matrix defined, create on the fly
        if(!newMatrices.isEmpty()) {    
            Id uId = getDefaultUser().Id;
            try {
                //insert the new matrices
                Database.insert(newMatrices);
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                        EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M3);
            }
            
            for(EBH_CampaignApprovalMatrix__c nm : newMatrices) {
                CampaignApprovalHierarchy.put(nm.EBH_Site__c, new List<EBH_CampaignApprovalGroup__c>());
            }
        }       
    }
    
    /*****************************************************************************************************************************
    @ Method:         getSites
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        retrieves the site picklist entries from the approval matrix object
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List<SelectOption>: list of picklist entries
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public List<SelectOption> getSites() {
        
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = EBH_CampaignApprovalMatrix__c.EBH_Site__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for(Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }
    
    /*****************************************************************************************************************************
    @ Method:         edit
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        toggles the view from read to edit mode
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void edit() {
        
        EditView = True;
    }

    /*****************************************************************************************************************************
    @ Method:         add
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        add new threshold and approver to the finance/control hierarchy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void add() {
        
        //add new hierarchy to the selected track (finance/control)
        CampaignApprovalHierarchy.get(Site).add(
                new EBH_CampaignApprovalGroup__c(EBH_CampaignApprovalMatrix__c = ApprovalMatrices.get(Site).Id));
    }
    
    /*****************************************************************************************************************************
    @ Method:         save
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        saves any change made in the matrix and hierarchy
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void save() {
        
        //final list to upsert
        List<EBH_CampaignApprovalGroup__c> ahs = new List<EBH_CampaignApprovalGroup__c>();
        
        //gather the records from different data structures
        for(String st : ApprovalMatrices.keySet()) {
            
            ahs.addAll(CampaignApprovalHierarchy.get(st));
            
        }
        
        //DMLs
        try {
            Database.upsert(ApprovalMatrices.values());
            Database.upsert(ahs);
            Database.delete(Database.query(EBH_ConstantsUtility.CAM_REMHRQUERY));
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M2);
        }
                
        //toggle the mode to read view
        EditView = False;
        
        //refresh the state
        initiate();
    }
    
    /*****************************************************************************************************************************
    @ Method:         remove
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        removes the hierarchy form the finance/controlling tables from the data structures
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void remove() {
        
        //populate the hierarchy id to the list to delete DML finally
        RemoveIds.add(RemoveId);   
        
        //check the track/table to remove row from
        removeHierarchy(CampaignApprovalHierarchy.get(Site), RemoveId);
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         removeHierarchy
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        removes the hierarchy form the finance/controlling tables from the data structures
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameters:     hierarchy: finance/control hierarchy list to remove from
                      hId:       record id to remove
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void removeHierarchy(List<EBH_CampaignApprovalGroup__c> hierarchy, Id hId) {
        
        Integer index = EBH_ConstantsUtility.CAS_ZERO;
        
        for(EBH_CampaignApprovalGroup__c ah : hierarchy) {
            if(ah.Id == hId) {
                hierarchy.remove(index);
                return;
            } else {
                index++;
            }
        }
    }
    
    /*****************************************************************************************************************************
    @ Method:         cancel
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        cancels the changes and resets the page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public void cancel() {
        
        //toggle the view
        EditView = False;
        
        //reset
        initiate();
    }
    
    /*****************************************************************************************************************************
    @ Method:         getDefaultUser
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        get a random sys admin user
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.05.2017 / JOY MONDOL / Created the method.
    *****************************************************************************************************************************/
    public User getDefaultUser() {
        
        Id pId;   //admin profile id
        User usr; //user to retutn
        
        try {
            //get the admin profile id
            pId = Database.query(EBH_ConstantsUtility.CAS_PROFQUERY)[0].Id;
            
            //return the first admin user found
            usr = (User)Database.query(EBH_ConstantsUtility.CAS_ADMUSRQUERY)[0];
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M1);
        }  
            
        return usr;
    }
}