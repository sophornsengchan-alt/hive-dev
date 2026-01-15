/*********************************************************************************************************************************
@ Interface:         IBatchExecutor
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0009430 Batch Jobs controll object
@                 So we can instatiate the batch class dynamically
@				 The batch class which intent to be called from Batch Job Runner trigger must implement this interface 
@				as well as the method runBatch()  to execute the batch itself
@ runnerId		: the external Id generated (before insert) and assigned to the BatchJobRunner; so the batch can update the status to the job
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.10.2019 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the IBatchExecutor.
*********************************************************************************************************************************/
public interface IBatchExecutor {
    
    void runBatch(String  runnerId);
    
}