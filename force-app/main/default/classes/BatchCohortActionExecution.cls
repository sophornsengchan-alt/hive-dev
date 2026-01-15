/*********************************************************************************************************************************
@ Class:          BatchCohortActionExecution
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        31.01.2024 / Sophal Noch / US-0014277 - Unable to delete Cohort Seller record
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.01.2024 / Sophal Noch / Created class
                : 15.02.2024 / Sophal Noch / US-0014756 - Data Synchronization of the Managed fields when the Account Manager on Active Cohort is updated
                : 16.02.2024 / Sophal Noch / US-0014755 - ADS - Cohort Seller and Seller nightly synch
*********************************************************************************************************************************/
public inherited sharing class BatchCohortActionExecution{

    
    /*********************************************************************************************************************************
    @ Class:         CohortSellerActivation
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014361 - Cohort Activation Process Part 2
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.11.2023 / Sophal Noch / Created the method.
                    :  15.11.2023 / Sophal Noch / US-0014353 - Cohort Deactivation Process
                    :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  30.01.2024 / Sophal Noch / US-0014277 : change method to inner class
    *********************************************************************************************************************************/
    public class CohortSellerActivation extends AbstractBatchCohortAction {
        // all cohort seller activation :

        public CohortSellerActivation(){
            this.initActionLabel = Label.Activate_Invite_Cohort_Seller;
        }
        public override String getSoql(){
            return BS_TO_SYNC_SOQL_WHEN_ACTIVATE_BOB;
        }
        public override String getActionLabel(){
            return System.Label.Sync_Cohort_Seller_To_Seller;
        }
        public override void execute (List<Sobject> listSobject){
            this.syncBsToAccount(listSobject);
        }
    }



    /*********************************************************************************************************************************
    @ Class:         CSActivationEmailSend
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014353 - Cohort Deactivation Process
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.11.2023 / Sophal Noch / Created the method.
                    :  11.12.2023 / Sophal Noch / US-0014362 - Ph 1 - Invite Sellers Button on Seller Management
                    :  30.01.2024 / Sophal Noch / US-0014277 : change method to inner class
    *********************************************************************************************************************************/
    public class CSActivationEmailSend extends AbstractBatchCohortAction {

        public override String getSoql(){
            return BOB_SOQL;
        }
        public override String getActionLabel(){
            return System.Label.Send_Email_After_Cohort_Seller_Activated;
        }
        public override void execute (List<Sobject> listSobject){
            this.sendEmailAfterCohortUpdate(listSobject);
        }
    }


    // all cohort seller deactivation
    public class CohortSellerDeactivation extends AbstractBatchCohortAction {

        public CohortSellerDeactivation(){
            this.initActionLabel = Label.Deactivate_Cohort_Seller;
        }
        public override String getSoql(){
            return BS_TO_SYNC_SOQL_WHEN_ACTIVATE_BOB;
        }
        public override String getActionLabel(){
            return System.Label.Unsync_Cohort_Seller_To_Seller;
        }
        public override void execute (List<Sobject> listSobject){
            this.syncBsToAccount(listSobject);
        }
    }
    public class CohortDeactivation extends AbstractBatchCohortAction {

        public override String getSoql(){
            return BOB_SOQL_TO_DEACTIVATE;
        }
        public override String getActionLabel(){
            return System.Label.Deactivate_Cohort;
        }
        public override void execute (List<Sobject> listSobject){
            this.deactivateCohort(listSobject);
        }
    }
    public class CSDectivationEmailSend extends AbstractBatchCohortAction {

        public override String getSoql(){
            return BOB_SOQL;
        }
        public override String getActionLabel(){
            return System.Label.Send_Email_After_Cohort_Seller_Deactivated;
        }
        public override void execute (List<Sobject> listSobject){
            this.sendEmailAfterCohortUpdate(listSobject);
        }
    }

    // selected cohort seller activation :
    public class SelectedCohortSellerActivation extends AbstractBatchCohortAction {

        public SelectedCohortSellerActivation(){
            this.initActionLabel = Label.Activate_Invite_Cohort_Seller;
        }
        public override String getSoql(){
            return BS_SELECTED_TO_SYNC_SOQL;
        }
        public override String getActionLabel(){
            return System.Label.Sync_Cohort_Seller_To_Seller;
        }
        public override void execute (List<Sobject> listSobject){
            this.syncBsToAccount(listSobject);
            this.changeNextSobjectToFromBsToBoB(listSobject);
        }
    }

    /*********************************************************************************************************************************
    @ Class:          SelectedCohortSellerDectivation
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        01.12.2023 / Sophal Noch / US-0014363 - Ph 1 - Deactivate Sellers button
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.12.2023 / Sophal Noch / Created the Class.
                    :  30.01.2024 / Sophal Noch / US-0014277 : change method to inner class
    *********************************************************************************************************************************/
    public class SelectedCohortSellerDectivation extends AbstractBatchCohortAction {
        // selected cohort seller deactivation :

        public SelectedCohortSellerDectivation(){
            this.initActionLabel = Label.Activate_Invite_Cohort_Seller;
        }
        public override String getSoql(){
            return BS_SELECTED_TO_SYNC_SOQL;
        }
        public override String getActionLabel(){
            return System.Label.Unsync_Cohort_Seller_To_Seller;
        }
        public override void execute (List<Sobject> listSobject){
            this.syncBsToAccount(listSobject);
            this.changeNextSobjectToFromBsToBoB(listSobject);
        }
    }

    public class AccountUnsync extends AbstractBatchCohortAction {
        // 30.01.2024 / Sophal Noch / US-0014277 : unsync deleted Account
        public override String getSoql(){
            return ACC_SOQL_TO_SYNC; // 16.02.2024 / Sophal Noch / US-0014755
        }
        public override String getActionLabel(){
            return System.Label.Unsync_Cohort_Seller_To_Seller;
        }
        public override void execute (List<Sobject> listSobject){
            this.unsyncAccount(listSobject);
        }
    }

    /*********************************************************************************************************************************
    @ Method:         synCohortSellerToAccount
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014755 - ADS - Cohort Seller and Seller nightly synch
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2024 / Sophal Noch / US-0014755 Created the method.
    *********************************************************************************************************************************/
    public static void synCohortSellerToAccount(String className, String methodName, List<BoB_Seller__c> listBobSeller){
        new SelectedCohortSellerActivation().setClassName(className).setMethodName(methodName).setSkipPublishEvent(true).execute(listBobSeller);
    }

    /*********************************************************************************************************************************
    @ Method:         unsyncAccount
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014755 - ADS - Cohort Seller and Seller nightly synch
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  16.02.2024 / Sophal Noch / US-0014755 Created the method.
    *********************************************************************************************************************************/
    public static void unsyncAccount(String className, String methodName, List<Account> listAccount){
        new AccountUnsync().setClassName(className).setMethodName(methodName).setSkipPublishEvent(true).execute(listAccount);
    }
        

}