/**
 * Created by Anujit on 15/10/2023.
 * This class is used to act as a dependency injection for the data factory classes
 */
public inherited sharing class DataCreator {
    private static final Map<sObjectType, System.Type> OBJECT_TO_FACTORY = new Map<sObjectType, System.Type>{
        //Account.sObjectType => AccountFactory.class,
        //Contact.sObjectType => ContactFactory.class,
        BoB_Seller__c.sObjectType => CohortSellerDataFactory.class,
        Bob_Seller_Category__c.sobjectType => CohortSellerCatPeformanceDataFactory.class,
        Action__c.sobjectType => ActionDataFactory.class,
        User.sObjectType => UserDataFactory.class
    };

    /**
     * This method is used to create records for a given object type
     */
    public static Object createRecords(sObjectType objectTypeToCreate,list<sobject> recordsToCreate) {
        IDataFactory factory = (IDataFactory) OBJECT_TO_FACTORY.get(objectTypeToCreate).newInstance();
        return factory.createRecords(recordsToCreate);
    }
    
    /**
     * This method is used to update records for a given object type
     */
    public static Object updateRecord(sObjectType objectTypeToUpdate,list<sobject> recordsToUpdate) {
        IDataFactory factory = (IDataFactory) OBJECT_TO_FACTORY.get(objectTypeToUpdate).newInstance();
        return factory.updateRecords(recordsToUpdate);
    }

    /**
     * This method is used to get records for a given objectID
     */
    public static Object getRecordbyId(sObjectType objectTypeToGet,id recordToGet) {
        IDataFactory factory = (IDataFactory) OBJECT_TO_FACTORY.get(objectTypeToGet).newInstance();
        return factory.getRecordbyId(recordToGet);
    }

    /**
     * This method is used to get records for a setof objectid
     */
    public static Object getRecordsByIds(sObjectType objectTypeToGet,set<id> recordIds) {
        IDataFactory factory = (IDataFactory) OBJECT_TO_FACTORY.get(objectTypeToGet).newInstance();
        return factory.getRecordsByIds(recordIds);
    }
    
    

}