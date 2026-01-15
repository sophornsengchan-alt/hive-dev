/*********************************************************************************************************************************
 @ Class:          APObjectiveMeasureTriggerHandler
 @ Version:        1.0
 @ Author:         Davy SORN
 @ Purpose:        Handler Class for AccountPlanObjectiveMeasureTrigger Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.03.2025 / Davy SORN / Created the handler class (US-0016888).
 *********************************************************************************************************************************/
public without sharing class APObjectiveMeasureTriggerHandler {

    /*****************************************************************************************************************************
    @ Method:         prePopulateField
    @ Version:        1.0
    @ Author:         Davy SORN	
    @ Purpose:        Update AccountPlanObjectiveMeasure's Start Actual field to Current Value
    @ Event:          before insert/update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      listNewMeasure:   List of new AccountPlanObjectiveMeasure from the trigger scope
                      mapOldMeasure:    Map of old AccountPlanObjectiveMeasure from the trigger scope
    --------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.03.2025 / Davy SORN / Created prePopulateField method (US-0016888).
    *****************************************************************************************************************************/    
    public static void prePopulateField(List<AccountPlanObjectiveMeasure> listNewMeasure, Map<Id,AccountPlanObjectiveMeasure> mapOldMeasure) {
        Boolean isNew = mapOldMeasure == null;
        for (AccountPlanObjectiveMeasure apom : listNewMeasure) {
            AccountPlanObjectiveMeasure oldMeasure = !isNew ? mapOldMeasure.get(apom.Id):null;
            if (String.isBlank(apom.Start_Actual__c) && (isNew || apom.CurrentValue != oldMeasure.CurrentValue)) {
                Decimal currentValue = apom.CurrentValue != null ? Decimal.valueOf(apom.CurrentValue) : null;
                apom.Start_Actual__c = currentValue != null ? currentValue.stripTrailingZeros().toPlainString() : apom.Start_Actual__c;
            }
        }
    }
}