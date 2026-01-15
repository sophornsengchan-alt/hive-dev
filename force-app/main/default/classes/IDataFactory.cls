/**
 * Created by Anujit on 15/10/23.
 */
 
public interface IDataFactory {
    /**
     * Returns a single record
     */
    sObject getRecord();

    /**
     * Returns a single record by Id
     */
    list<sObject> getRecordbyId(Id sObjectId);

    /**
     * Returns a list of records
     */
    List<sObject> getRecords();

    /**
     * Returns a list of records by Id
     */
    List<sObject> getRecordsByIds(set<id> sObjectIds);

    /**
     * create a single record
     */
    sObject createRecord(sObject sObjectRecord);

    /**
     * create a list of records
     */
    List<sObject> createRecords(List<sObject> sObjects);

    /**
     * update a single record
     */
    sObject updateRecord(id sObjectId);

    /**
     * update a list of records
     */
    List<sObject> updateRecords(List<sobject> sObjects);

    /**
     * upsert a single record
     */
    sObject upsertRecord(sobject sObjectRecord);

    /**
     * upsert a list of records
     */
    List<sObject> upsertRecords(List<sobject> sObjects);

    /**
     * delete a single record
     */
    sObject deleteRecord(sobject sObjectRecord);

    /**
     * delete a list of records
     */
    List<sObject> deleteRecords(List<sobject> sObjects);

    /**
     * merge a list of records
     */
    void dmlMerge(SObject masterRecord, List<SObject> objList);

}