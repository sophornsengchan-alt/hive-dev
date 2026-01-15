/*********************************************************************************************************************************
@ Class:         ContractAcceptanceController
@ Version:       1.0
@ Author:        LoumAng SENG(loumang.seng@gaea-sys.com)
@ Purpose:       US-0014508 - Preloved Automated Engineering Email
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 12.12.2023 / LoumAng SENG(loumang.seng@gaea-sys.com)/ Created the class.
@                 06.11.2024 / Mony Nou / US-0015532 - Extend Pre-Loved Partner Contract type to AU
*********************************************************************************************************************************/
public with sharing class ContractAcceptanceController {

    public Contract con { get; set; }
    public String site { get; set; } //MN-06112024-US-0015532
    public List<EBH_ContractSeller__c> contractSellers {get; set;}

    /*****************************************************************************************************************************
    @ Method:       getPage
    @ Author:       LoumAng SENG(loumang.seng@gaea-sys.com)
    @ Purpose:      US-0014508 - Preloved Automated Engineering Email              
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  12.12.2023 / LoumAng SENG(loumang.seng@gaea-sys.com)/ Created the method.
    @*****************************************************************************************************************************/
    public ContractAcceptanceController getPage(){
        // controller for visual force component page PreLovedContractAcceptance.
        // The reason to use WithoutSharing is because the user who is sending the email is "Deal Acceptance Site Guest User" user who doesn't have access to object EBH_ContractSeller__c
        contractSellers = WithoutSharing.doQuery('SELECT EBH_BusinessName__r.Name,EBH_BusinessName__r.EBH_OracleID__c FROM EBH_ContractSeller__c WHERE EBH_ContractNumber__c ='+ApexUtil.closeSQoute(con.Id),'','');
        return this;
    }

}