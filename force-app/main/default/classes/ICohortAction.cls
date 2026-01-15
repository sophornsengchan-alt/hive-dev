/*********************************************************************************************************************************
@ Class:          ICohortAction
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        31.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.01.2024 / Sophal Noch / Created class
                : 16.02.2024 / Sophal Noch / US-0014755 - ADS - Cohort Seller and Seller nightly synch
*********************************************************************************************************************************/
public interface ICohortAction{

    String getSoql();
    String getActionLabel();
    void execute (List<Sobject> listSobject);

    Database.QueryLocator startBatch();
    List<SObject> executeQuery();
    ICohortAction setAction(String action);
    ICohortAction setSoqlIndex(Integer soqlIndex);
    ICohortAction setSetSobjIds(Set<String> setSobjIds);
    ICohortAction setClassName(String className);
    ICohortAction setMethodName(String methodName); // 16.02.2024 / Sophal Noch / US-0014755
    ICohortAction setSkipPublishEvent(Boolean skipPublishEvent); // 16.02.2024 / Sophal Noch / US-0014755
    Set<String> getNextSobjIds();
    void publishInitEvent();
    void publishSuccessEvent();
    void publishErrorEvent(Exception e);

}