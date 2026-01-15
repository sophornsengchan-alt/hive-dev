/*
@class ApexSafe
@author vadhanak 
@purpose: This class is used to perform DML operations on SObjects with FLS and CRUD checks 
		- apexcrudviolation
		- ApexFlsViolationRule
@changelog
        - 20/12/2023 - vadhanak - initial version
		- 06/06/2024 - Acmatac Seing - US-0015181 Create without sharing query method
		- 09/08/2024 - vadhanak voun - Database.DMLOptions for insert/update
    - 27/02/2025 - vadhanak voun - SuperDML for bypassing sharing 
    - 21/08/2025 - Sothea Horn - US-0033306 - Increase to version 64
*/
public with sharing class ApexSafe {
  private static SafeDML sdml;
  private static SafeQuery squery;
  private static ISafeQuery spQuery;
  private static ISafeDML spDML;

  public static SafeDML dml() {
    if (sdml == null) {
      sdml = new SafeDML();
    }
    return sdml;
  }
  public static SafeQuery query() {
    if (squery == null) {
      squery = new SafeQuery();
    }
    return squery;
  }

  //NK:27/02/2025
  public static ISafeDML dml(Boolean isSuperDML) 
  {
    if (isSuperDML) 
    {
      if (spDML == null) 
      {
        spDML = new SuperDML();
      }
      return spDML;
    } else {
      return dml();
    }
  }

  // 06/06/2024 - Acmatac Seing - US-0015181
  // NOTE: Super Query is for critical using only. Who want to use it required to discuss with technical lead first
  public static ISafeQuery query(Boolean isSuperQuery) {
    if (isSuperQuery) {
      if (spQuery == null) {
        spQuery = new SuperQuery();
      }
      return spQuery;
    } else {
      return query();
    }
  }

  public inherited sharing virtual class SafeDML implements ISafeDML {
    //in case we want to bypass security check
    private boolean isSecCheck = true; //security check
    Database.DMLOptions dlo = null;

    private SafeDML() {
      System.debug('Now it is not empty block anymore.');
    }
    public SafeDML secCheck(boolean isSecCheck) {
      this.isSecCheck = isSecCheck;
      return this;
    }
    public SafeDML setDMLOPtion(Database.DMLOptions dlo) {
      this.dlo = dlo;
      return this;
    }
    //If optAllOrNone is set to true, all changes are rolled back if any record causes errors.
    //The default for this property is false and successfully processed records are committed while records with errors aren't.
    //If optAllOrNone is set to false and a record fails, the remainder of the DML operation can still succeed. You must iterate through the returned results to identify which records succeeded or failed.
    public virtual Database.SaveResult[] doInsert(
      List<SObject> listObj,
      boolean allOrNone
    ) {
      if (isSecCheck) {
        return Database.insert(
          listObj,
          getDMLOPtion(allOrNone),
          AccessLevel.USER_MODE
        );
      } else {
        return Database.insert(
          listObj,
          getDMLOPtion(allOrNone),
          AccessLevel.SYSTEM_MODE
        );
      }
    }

    public virtual Database.SaveResult[] doUpdate(
      List<SObject> listObj,
      boolean allOrNone
    ) {
      if (isSecCheck) {
        return Database.update(
          listObj,
          getDMLOPtion(allOrNone),
          AccessLevel.USER_MODE
        );
      } else {
        return Database.update(
          listObj,
          getDMLOPtion(allOrNone),
          AccessLevel.SYSTEM_MODE
        );
      }
    }

    public virtual Database.UpsertResult[] doUpsert(
      List<SObject> listObj,
      Schema.SObjectField extId,
      boolean allOrNone
    ) {
      if (isSecCheck) {
        return Database.Upsert(
          listObj,
          extId,
          allOrNone,
          AccessLevel.USER_MODE
        );
      } else {
        return Database.Upsert(
          listObj,
          extId,
          allOrNone,
          AccessLevel.SYSTEM_MODE
        );
      }
    }

    public virtual Database.DeleteResult[] doDelete(
      List<SObject> listObj,
      Boolean allOrNone
    ) {
      if (isSecCheck) {
        return Database.delete(listObj, allOrNone, AccessLevel.USER_MODE);
      } else {
        return Database.delete(listObj, allOrNone, AccessLevel.SYSTEM_MODE);
      }
    }

    //NK:09/08/2024
    protected Database.DMLOptions getDMLOPtion(Boolean allOrNone) {
      if (dlo == null) {
        dlo = new Database.DMLOptions();
      }
      dlo.OptAllOrNone = allOrNone;
      return dlo;
    }
  }

  public inherited sharing virtual class SafeQuery implements ISafeQuery {
    private SafeQuery() {
      System.debug('now it is not empty block anymore');
    }
    private boolean isSecCheck = true; //security check

    //in case we want to bypass security check
    public SafeQuery secCheck(boolean secCheck) {
      this.isSecCheck = secCheck;
      return this;
    }

    //no bind values
    public List<Sobject> doQuery(String soql) {
      return doQuery(soql, new Map<String, Object>());
    }

    public virtual List<Sobject> doQuery(
      String soql,
      Map<String, Object> bindValues
    ) {
      if (isSecCheck) {
        return Database.queryWithBinds(soql, bindValues, AccessLevel.USER_MODE);
      } else {
        return Database.queryWithBinds(
          soql,
          bindValues,
          AccessLevel.SYSTEM_MODE
        );
      }
    }

    //no bind values
    public Integer doCount(String soql) {
      return doCount(soql, new Map<String, Object>());
    }

    public Integer doCount(String soql, Map<String, Object> bindValues) {
      if (isSecCheck) {
        return Database.countQueryWithBinds(
          soql,
          bindValues,
          AccessLevel.USER_MODE
        );
      } else {
        return Database.countQueryWithBinds(
          soql,
          bindValues,
          AccessLevel.SYSTEM_MODE
        );
      }
    }
  }

  //Using SuperQuery must be very careful and only when SafeQuery.secCheck(false) is not enough.
  public without sharing class SuperQuery extends SafeQuery implements ISafeQuery {
    //override to allow without sharing
    public override List<Sobject> doQuery(
      String soql,
      Map<String, Object> bindValues
    ) {
      return super.doQuery(soql, bindValues);
    }
  }

  public interface ISafeQuery {
    ISafeQuery secCheck(boolean secCheck);
    List<Sobject> doQuery(String soql);
    List<Sobject> doQuery(String soql, Map<String, Object> bindValues);
    Integer doCount(String soql);
    Integer doCount(String soql, Map<String, Object> bindValues);
  }

  public interface ISafeDML {
    ISafeDML secCheck(boolean isSecCheck);
    ISafeDML setDMLOPtion(Database.DMLOptions dlo);
    Database.SaveResult[] doInsert(List<SObject> listObj, boolean allOrNone);
    Database.SaveResult[] doUpdate(List<SObject> listObj, boolean allOrNone);
    Database.UpsertResult[] doUpsert(List<SObject> listObj,Schema.SObjectField extId,boolean allOrNone);
    Database.DeleteResult[] doDelete(List<SObject> listObj, Boolean allOrNone);
    
  }
  //NK:27/02/2025
  //Using SuperDML must be very careful and only when SafeQuery.secCheck(false) is not enough.
  public without sharing class SuperDML extends SafeDML  implements ISafeDML {
    //override to allow without sharing
    public override Database.SaveResult[] doInsert(
      List<SObject> listObj,
      boolean allOrNone
    ) {
      return super.doInsert(listObj, allOrNone);
    }
    public override Database.SaveResult[] doUpdate(
      List<SObject> listObj,
      boolean allOrNone
    ) {
      return super.doUpdate(listObj, allOrNone);
    }
    public override Database.UpsertResult[] doUpsert(
      List<SObject> listObj,
      Schema.SObjectField extId,
      boolean allOrNone
    ) {
      return super.doUpsert(listObj, extId, allOrNone);
    }
    public override Database.DeleteResult[] doDelete(
      List<SObject> listObj,
      Boolean allOrNone
    ) {
      return super.doDelete(listObj, allOrNone);
    }
  }
}