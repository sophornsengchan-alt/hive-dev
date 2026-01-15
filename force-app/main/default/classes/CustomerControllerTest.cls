/*********************************************************************************************************************************
@ Class:          CustomerControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.01.2024 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class CustomerControllerTest {

    /*********************************************************************************************************************************
    @ Method:         unlinkParentLegalEntity
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.01.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest
    public static void testUnlinkParentLegalEntity(){

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        Map<String, Object> mapResult = CustomerController.unlinkParentLegalEntity(sellers[0].Id);
        System.assertEquals('ok', (String)mapResult.get('status'));

        mapResult = CustomerController.unlinkParentLegalEntity('testing_error_id');
        System.assertEquals('ko', (String)mapResult.get('status'));

    }
}