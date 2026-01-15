/*********************************************************************************************************************************
@ Class:         ProTrader_FollowupController
@ Version:       1.0
@ Author:        vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0009723 - [Pro-Trader] New Home Page for Pro Trader Advisors
@                Controller for aura: ProTrader_Followup    
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	29.06.2021 / vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public without sharing class ProTrader_FollowupController {
     
    /*****************************************************************************************************************************
    @ Method:   apexInit
    @ Version:  1.0
    @ Author: 	vadhanak voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:	US-0009723 - [Pro-Trader] New Home Page for Pro Trader Advisors
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.06.2021 /  vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the  Method.
    *****************************************************************************************************************************/    
    @AuraEnabled
    public static Map<String,Object> apexInit(String bobId,String fieldSetName,String soqlWhere,String orderBy)
    {
        Map<String,Object> mapResult = new Map<String,Object>();
        List<Object> listColHeader = new List<Object>();
        Map<String,Object> mapItem = new Map<String,Object>();
        Set<String> setFields = new Set<String>();
    
        Schema.FieldSet fieldSet = Schema.SObjectType.BoB_Seller__c.fieldSets.getMap().get(fieldSetName);
        for(Schema.FieldSetMember fld : fieldSet.getFields())
        {  
            String fName  = fld.getFieldPath();
            setFields.add(fName);
            Boolean isRef = fName.contains('.');
             
            if(isRef)
            {
                setFields.add(fName.substring(0,fName.lastIndexOf('.'))+'.Id');
            }

            listColHeader.add(
                new Map<String,Object>
                {
                    'label'=>fld.getLabel(),
                    'fieldName'=>fld.getFieldPath(),
                    'type'=>String.valueof(fld.getType()).toLowerCase(),
                    'isRef'=>isRef
                }
            );
        }
        
        String soql   = 'SELECT '+String.join(new List<String>(setFields), ',') + ' FROM BoB_Seller__c ';
        mapResult.put('soql',soql);
        mapResult.put('listColHeader',listColHeader);

        return mapResult;
    }

     
}