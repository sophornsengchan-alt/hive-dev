@isTest
public class DMLWorkerTest {
  // Concrete implementation of the abstract DMLWorker for testing
  public class DMLWorkerImpl extends DMLWorker {
    public DMLWorkerImpl(
      List<SObject> listSobject,
      String className,
      String methodName,
      String dmlType
    ) {
      super(listSobject, className, methodName, dmlType);
      retry_counter = 0;
    }

    public void setCounter() {
      retry_counter++;
    }

    public void doRetry() {
      System.enqueueJob(
        new DMLWorkerImpl(listSobject, className, methodName, dmlType)
      );
    }

    // Method to expose retry_counter for assertions in tests
    public Integer getRetryCounter() {
      return retry_counter;
    }
  }

  @isTest
  static void testDMLWorker() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    acc.Name = 'Updated Test Account';

    Test.startTest();

    DMLWorkerImpl worker = new DMLWorkerImpl(
      new List<SObject>{ acc },
      'DMLWorkerTest',
      'testDMLWorker',
      'update'
    );
    worker.execute(null);

    Test.stopTest();

    Account updatedAcc = [SELECT Name FROM Account WHERE Id = :acc.Id];
    System.assertEquals(
      'Updated Test Account',
      updatedAcc.Name,
      'Account name should be updated'
    );
  }

  @isTest
  static void testDMLWorkerWithDelete() {
    Account acc = new Account(Name = 'Account to Delete');
    insert acc;

    Test.startTest();

    DMLWorkerImpl worker = new DMLWorkerImpl(
      new List<SObject>{ acc },
      'DMLWorkerTest',
      'testDMLWorkerWithDelete',
      'delete'
    );
    worker.execute(null);

    Test.stopTest();

    List<Account> accList = [SELECT Id FROM Account WHERE Id = :acc.Id];
    System.assertEquals(0, accList.size(), 'Account should be deleted');
  }

  @isTest
  static void testRetryLogic() {
    Account invalidAcc = new Account(Id = '001000000000000AAA'); // Invalid ID for testing

    Test.startTest();

    DMLWorkerImpl worker = new DMLWorkerImpl(
      new List<SObject>{ invalidAcc },
      'DMLWorkerTest',
      'testRetryLogic',
      'update'
    );
    worker.execute(null);

    Test.stopTest();

    System.assert(
      worker.getRetryCounter() > 0,
      'Retry counter should be incremented after exception'
    );
  }
}