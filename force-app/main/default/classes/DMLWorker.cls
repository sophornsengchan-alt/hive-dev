/*********************************************************************************************************************************
@ Class:          DMLWorker
@ Version:        1.0
@ Author:         Vadhanak Voun
@ Purpose:         allow dml to retry by Queuebale transaction
                   TriggerHandler need to extend and implement the required methods
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13.01.2019 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public abstract without sharing class DMLWorker implements Queueable{
    public final static Integer RETRY_LIMIT = 5;
    protected List<SObject> listSobject;
    protected Integer retry_counter;
    protected String className;
    protected String methodName;
    protected String dmlType = 'update'; //default
    public DMLWorker(List<SObject> listSobject,String className,String methodName)
    {
    	this.listSobject = listSobject;
		this.className = className;
    	this.methodName = methodName;
    }
    public DMLWorker(List<SObject> listSobject,String className,String methodName,String dmlType)
    {
    	this(listSobject,className,methodName);
    	this.dmlType = dmlType;
    }
	public void doUpdate()
	{
		execute(null);
	}   
    public void execute(QueueableContext context) 
    {
    	try
    	{
    		setCounter();
    		if(dmlType=='update')
    		{
    			update listSobject;
    		}else if(dmlType=='delete')
    		{
    			delete listSobject;
    		}else if(dmlType=='insert')
    		{
    			insert listSobject;
    		}
    	}catch (System.DMLException ex) 
   	 	{if (StatusCode.UNABLE_TO_LOCK_ROW==ex.getDmlType(0)){if(RETRY_LIMIT>=retry_counter){EBH_ApexLogger.logError(new List<Exception> { ex }, className+'(DMLWorker-LIMIT)', methodName);}else{doRetry();}}else{EBH_ApexLogger.logError(new List<Exception> { ex }, className+'(DMLWorker-UNKNOWN-DML)', methodName);}
   	 	}catch(Exception ex2)
   	 	{EBH_ApexLogger.logError(new List<Exception> { ex2 }, className+'(DMLWorker-UNKNOWN-Exception)', methodName); }
    }
    //children must increase the counter variable and retry_counter
    abstract void setCounter();
    abstract void doRetry(); //instantiate child class to retry
}