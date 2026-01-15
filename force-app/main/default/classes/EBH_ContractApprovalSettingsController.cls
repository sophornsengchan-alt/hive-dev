/*********************************************************************************************************************************
@ Class:          EBH_ContractApprovalSettingsController
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Controller Class for EBH_ContractApprovalSettings page
EPH-14 : Contract Approval
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the class.
*********************************************************************************************************************************/

public with sharing class EBH_ContractApprovalSettingsController {
    
    /*global variables/properties*/    
    public Id      RemoveId  { get; set; } //hierarchy id of the selected/removed row
    public String  Site      { get; set; } //site of the selected section
    public String  Hierarchy { get; set; } //hierarchy type (finance/controlling) of the selected table
    public Boolean EditView  { get; set; } //edit mode flag
    public String  HRFINANCE { get; set; } //Finance string value for finance hierarchy
    public String  HRCONTROL { get; set; } //Controlling string value for control hierarchy
    public String  HRBU      { get; set; } //BU Approver string value for control hierarchy
    
    public Map<String, RecordType>                             HierarchyTypes               { get; set; } //record types
    public Map<String, EBH_ContractApprovalMatrix__c>          ApprovalMatrices             { get; set; } //master matrix
    public Map<String, List<EBH_ContractApprovalHierarchy__c>> FinanceApprovalHierarchy     { get; set; } //finance hierarchy
    public Map<String, List<EBH_ContractApprovalHierarchy__c>> ControllingApprovalHierarchy { get; set; } //control heirarchy
    public Map<String, List<EBH_ContractApprovalHierarchy__c>> buApprovalHierarchy     { get; set; } //finance hierarchy
    public Map<String, List<EBH_BUApproverGroup__c>> BUusers {set;get;} // to add/remove public group users easily
    /*private variables/properties*/    
    private List<Id> RemoveIds = new List<Id>();
    
    /*****************************************************************************************************************************
@ Constructor:    EBH_ContractApprovalSettingsController
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Initialises the class for controller instance.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public EBH_ContractApprovalSettingsController() {     
        initiate();
    }
    
    /*****************************************************************************************************************************
@ Method:         initiate
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Initialises the class.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public void initiate() {
        
        //initialise the constants refered in page
        HRFINANCE = EBH_ConstantsUtility.CAS_FIN;
        HRCONTROL = EBH_ConstantsUtility.CAS_CON;
        HRBU = EBH_ConstantsUtility.CAS_BU;
        BUusers = new Map<String,List<EBH_BUApproverGroup__c>>();
        
        List<RecordType> rectypes;                    //record types            
        List<EBH_ContractApprovalMatrix__c> matrices; //approval matrices
        
        //initialise the master data structures for the page
        HierarchyTypes               = new Map<String, RecordType>();        
        ApprovalMatrices             = new Map<String, EBH_ContractApprovalMatrix__c>();
        FinanceApprovalHierarchy     = new Map<String, List<EBH_ContractApprovalHierarchy__c>>();
        buApprovalHierarchy     = new Map<String, List<EBH_ContractApprovalHierarchy__c>>();
        ControllingApprovalHierarchy = new Map<String, List<EBH_ContractApprovalHierarchy__c>>();
        
        try {
            //fetch the record types
            rectypes = Database.query(EBH_ConstantsUtility.CAS_RECTYPQUERY);
            //fetch the record types
            matrices = Database.query(EBH_ConstantsUtility.CAS_MTRXPQUERY);
        } catch(Exception ex) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                    EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M4);
        }
        
        //loop through the record types to populate the loacl hierarchy datastructure
        for(RecordType rt : rectypes) {
            HierarchyTypes.put(rt.DeveloperName, rt);
        }
        buUsers.put(null, new List<EBH_BUApproverGroup__c>());
        //loop through the matrix and the hierarchy per site to populate the loacl hierarchy datastructure
        for(EBH_ContractApprovalMatrix__c am : matrices) {
            
            ApprovalMatrices.put(am.EBH_Site__c, am);
            
            List<EBH_ContractApprovalHierarchy__c> finAhs = new List<EBH_ContractApprovalHierarchy__c>();
            List<EBH_ContractApprovalHierarchy__c> conAhs = new List<EBH_ContractApprovalHierarchy__c>();
            List<EBH_ContractApprovalHierarchy__c> bu = new List<EBH_ContractApprovalHierarchy__c>();
            
            //loop through the hierarchy
            for(EBH_ContractApprovalHierarchy__c ah : am.EBH_ContractApprovalHierarchies__r) {
                if(ah.RecordType.DeveloperName == EBH_ConstantsUtility.CAS_FINANCE) {
                    finAhs.add(ah);
                } else if(ah.RecordType.DeveloperName == EBH_ConstantsUtility.CAS_CONTROLLING) {
                    conAhs.add(ah);
                } else if(ah.RecordType.DeveloperName == EBH_ConstantsUtility.CAS_BURECORD){
                    bu.add(ah);
                }
            }
            
            //populate the hierarchy maps for finance anf control tracks
            FinanceApprovalHierarchy.put(am.EBH_Site__c, finAhs);
            buApprovalHierarchy.put(am.EBH_Site__c, bu);
            ControllingApprovalHierarchy.put(am.EBH_Site__c, conAhs);
            
            getBUGroupUsers();
        }
    }
    
    private void getBUGroupUsers(){
        
        List<EBH_BUApproverGroup__c > usrs = new List< EBH_BUApproverGroup__c >();
        Set<ID> hierarchyIds = new Set<ID>();
        for( List<EBH_ContractApprovalHierarchy__c> hierarchy: buApprovalHierarchy.values()){
            for( EBH_ContractApprovalHierarchy__c hiera: hierarchy){
                hierarchyIds.add(hiera.Id);
                buUsers.put(hiera.Id, new List<EBH_BUApproverGroup__c>());
            }
            
        }
        Set<ID> userIDs = new Set<ID>();
        List<GroupMember> gms = new List<GroupMember>();
        Map<String, User> userMap = new Map<String,User>();
        
        
        for(EBH_BUApproverGroup__c grpName : [SELECT EBH_BUHierarchy__r.EBH_BUApproverGroup__c ,EBH_BUHierarchy__c,EBH_Approver__c, EBH_Site__c , EBH_Approver__r.Name from EBH_BUApproverGroup__c  where 
                                              EBH_BUHierarchy__c IN :hierarchyIds]){
                                                  
                                                  usrs = buUsers.get(grpName.EBH_BUHierarchy__c);
                                                  usrs.add(grpName);
                                                  buUsers.put(grpName.EBH_BUHierarchy__c, usrs);
                                                  
                                              }
    }
    
    
    /*****************************************************************************************************************************
@ Method:         createNewMatrices
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Creates new approval matrix for the sites that does not exits for the time.
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public void createNewMatrices() {
        
        List<EBH_ContractApprovalMatrix__c> newMatrices = new List<EBH_ContractApprovalMatrix__c>();
        
        //loop through the site picklist metadata and check if apptoval matrix esists
        for(SelectOption st : getSites()) {
            
            if(!ApprovalMatrices.containsKey(st.getValue())) {
                newMatrices.add(new EBH_ContractApprovalMatrix__c(EBH_Site__c = st.getValue()));
            }
        }
        
        //if not every site has got approval matrix defined, create on the fly
        if(!newMatrices.isEmpty()) {
            
            Id uId = getDefaultUser().Id;
            
            for(EBH_ContractApprovalMatrix__c nm : newMatrices) {
                nm.EBH_LegalApprover__c = uId;
                nm.EBH_FinancePrecheckApprover__c = uId;
            }   
            
            try {
                //insert the new matrices
                Database.insert(newMatrices);
            } catch(Exception ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, 
                                        EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M3);
            }
            
            for(EBH_ContractApprovalMatrix__c nm : newMatrices) {
                FinanceApprovalHierarchy.put(nm.EBH_Site__c, new List<EBH_ContractApprovalHierarchy__c>());
                buApprovalHierarchy.put(nm.EBH_Site__c, new List<EBH_ContractApprovalHierarchy__c>());
                ControllingApprovalHierarchy.put(nm.EBH_Site__c, new List<EBH_ContractApprovalHierarchy__c>());
            }
        }       
    }
    
    /*****************************************************************************************************************************
@ Method:         getSites
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        retrieves the site picklist entries from the approval matrix object
------------------------------------------------------------------------------------------------------------------------------
@ Returns:        List<SelectOption>: list of picklist entries
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public List<SelectOption> getSites() {
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = EBH_ContractApprovalMatrix__c.EBH_Site__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        
        return options;
    }
    
    /*****************************************************************************************************************************
@ Method:         edit
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
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
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        add new threshold and approver to the finance/control hierarchy
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public void add() {        
        
        //add new hierarchy to the selected track (finance/control)
        if(Hierarchy == HRFINANCE) {
            FinanceApprovalHierarchy.get(Site).add(
                new EBH_ContractApprovalHierarchy__c(EBH_ContractApprovalMatrix__c = ApprovalMatrices.get(Site).Id,
                                                     RecordTypeId = HierarchyTypes.get(EBH_ConstantsUtility.CAS_FINANCE).Id));
        } else if(Hierarchy == HRCONTROL) {
            // if( approvalMatrices.containsKey( site))
            ControllingApprovalHierarchy.get(Site).add(
                new EBH_ContractApprovalHierarchy__c(EBH_ContractApprovalMatrix__c = ApprovalMatrices.get(Site).Id,
                                                     RecordTypeId = HierarchyTypes.get(EBH_ConstantsUtility.CAS_CONTROLLING).Id));
        } else if(Hierarchy == HRBU){
            buApprovalHierarchy.get(Site).add(
                new EBH_ContractApprovalHierarchy__c(EBH_ContractApprovalMatrix__c = ApprovalMatrices.get(Site).Id,
                                                     RecordTypeId = HierarchyTypes.get(EBH_ConstantsUtility.CAS_BURecord).Id));
            
        }else if( Hierarchy == 'BUUSER'){
            if( site != ''){
                buUsers.get(Site).add(
                    new EBH_BUApproverGroup__c(EBH_BUHierarchy__c = site));
            }else{
                buUsers.get(Site).add(
                    new EBH_BUApproverGroup__c( ));
            }
            
        }
    }
    
    /*****************************************************************************************************************************
@ Method:         save
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        saves any change made in the matrix and hierarchy
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public void save() {        
        //final list to upsert
        List<EBH_ContractApprovalHierarchy__c> ahs = new List<EBH_ContractApprovalHierarchy__c>();
        List<EBH_BUApproverGroup__c> bus = new List<EBH_BUApproverGroup__c>();
        
        //gather the records from different data structures
        for(String st : ApprovalMatrices.keySet()) {
            
            ahs.addAll(FinanceApprovalHierarchy.get(st));
            ahs.addAll(ControllingApprovalHierarchy.get(st));
            ahs.addAll(buApprovalHierarchy.get(st));
            
        }
        
        Set<ID> sUsers = new set<id>();
        for(String st: buUsers.keyset()){
         	   
            bus.addAll(buUsers.get(st));
        }
        for (EBH_BUApproverGroup__c b :bus){
            if(b.EBH_Approver__c!=null){
                susers.add(b.ebh_approver__c);
            }
        }
        //DMLs
        try {
            Database.upsert(ApprovalMatrices.values());
            Database.upsert(ahs);
            Database.delete(Database.query(EBH_ConstantsUtility.CAS_REMHRQUERY));
            Database.delete(Database.query(EBH_ConstantsUtility.CAS_REMBUQUERY));
            Database.upsert(bus);
        } catch(Exception ex) {
            // 04.10.2021 / TIN SRONG, call method
			handleError(ex,susers,ahs,ApprovalMatrices);
        }
        
        //toggle the mode to read view
        EditView = False;
        
        //refresh the state
        initiate();
    }
    
    /*********************************************************************************************************************************
    @ Class:          handleError
    @ Version:        1.0
    @ Author:         SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:        make it easy to call from test class
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.10.2021 / SRONG TIN / Created method.
    *********************************************************************************************************************************/
    @TestVisible
	private void handleError(Exception ex,Set<ID> susers,List<EBH_ContractApprovalHierarchy__c> ahs,Map<String, EBH_ContractApprovalMatrix__c> ApprovalMatrices){
		for (EBH_ContractApprovalHierarchy__c cah: ahs){
                susers.add(cah.EBH_Approver__c);
            }
            for (EBH_ContractApprovalMatrix__c am:ApprovalMatrices.values()){
                if(am.EBH_FinancePrecheckApprover__c!=null)
                {susers.add(am.EBH_FinancePrecheckApprover__c);}
                if(am.EBH_LegalApprover__c!=null){
                    susers.add(am.EBH_LegalApprover__c);
                }
                    
            }
            
            String SInactiveUser ='';
            Integer numOfUsers=0;
            for (User u:[SELECT ID,username,firstname,lastname from user where isactive=false and id in :susers]){
                SInactiveUser+=U.FIRSTNAME + ' ' + U.LASTname + ',';
                numOfUsers++;
            }
            if (numOfusers>0){
            SInactiveUser=SInactiveUser.substring(0, SInactiveUser.length()-1) ;    
            }
            
            
            //Following user{0} is inactive: {1} . Please get rid of {2}
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,String.format(Label.Inactive_user_Error, new List<String>{(numOfUsers>1?'s':''),(numOfUsers>1?'are':'is'),SInactiveUser,(numOfUsers>1?'them':'him')})));
            
        	if (!Test.isRunningTest()) {
            EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.CAS_CLASSNAME, EBH_ConstantsUtility.CAS_M2);
            }
	}
    
    /*****************************************************************************************************************************
@ Method:         remove
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        removes the hierarchy form the finance/controlling tables from the data structures
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public void remove() {        
        //populate the hierarchy id to the list to delete DML finally
        RemoveIds.add(RemoveId);   
        
        //check the track/table to remove row from
        if(Hierarchy == EBH_ConstantsUtility.CAS_FIN) {
            removeHierarchy(FinanceApprovalHierarchy.get(Site), RemoveId);
        } else if( Hierarchy == EBH_ConstantsUtility.CAS_CON) {
            removeHierarchy(ControllingApprovalHierarchy.get(Site), RemoveId);
        } else if(Hierarchy == EBH_ConstantsUtility.CAS_BU){
            removeHierarchy(buApprovalHierarchy.get(Site), RemoveId);
        } else{
            removeBUHierarchy(buUsers.get(Site), RemoveId);
        }
        
    }
    
    /*****************************************************************************************************************************
@ Method:         removeHierarchy
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        removes the hierarchy form the finance/controlling tables from the data structures
------------------------------------------------------------------------------------------------------------------------------
@ Parameters:     hierarchy: finance/control hierarchy list to remove from
hId:       record id to remove
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.05.2017 / JOY MONDOL / Created the method.
*****************************************************************************************************************************/
    public void removeHierarchy(List<EBH_ContractApprovalHierarchy__c> hierarchy, Id hId) {        
        Integer index = EBH_ConstantsUtility.CAS_ZERO;
        
        if( hierarchy != null) {
            for(EBH_ContractApprovalHierarchy__c ah : hierarchy) {
                if(ah.Id == hId) {
                    hierarchy.remove(index);
                    return;
                } else {
                    index++;
                }
            }
        }
    }
    /*****************************************************************************************************************************
@ Method:         removeBUHierarchy
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        removes the hierarchy form the finance/controlling tables from the data structures
------------------------------------------------------------------------------------------------------------------------------
@ Parameters:     hierarchy: finance/control hierarchy list to remove from
hId:       record id to remove
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.11.2017 / NEHA LUND / Created the method.
*****************************************************************************************************************************/
    public void removeBUHierarchy(List< EBH_BUApproverGroup__c > hierarchy, Id hId) {        
        Integer index = EBH_ConstantsUtility.CAS_ZERO;
        
        if( hierarchy != null) {
            for(EBH_BUApproverGroup__c ah : hierarchy) {
                if(ah.Id == hId) {
                    hierarchy.remove(index);
                    return;
                } else {
                    index++;
                }
            }
        }
    }    
    /*****************************************************************************************************************************
@ Method:         cancel
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
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
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
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