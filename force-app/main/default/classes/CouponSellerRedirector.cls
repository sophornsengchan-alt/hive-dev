/*********************************************************************************************************************************
@ Class:          CouponSellerRedirector
@ Version:        1.0
@ Author:         LoumAng SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0007360 - wrong coupon seller record when click on NEW
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.04.2020 / LoumAng SENG / Created the class.
@               : 21.08.2023 / Sambath Seng / US-0013978 - Introduce new Coupon Seller type for Long term Coupons		
@               : 25.07.2025 / Anu / US-0033050 AC2: When new coupon seller records are uploaded in HIVE I can see the new Record Type of Master Agreement Seller has been created		
@               : 12.09.2025 / Mony / US-0033151 - POP - Coupon Seller - Create New Record Type (Program Coupon Seller)  
*********************************************************************************************************************************/
public class CouponSellerRedirector {
    private static Map<String, String> mCouponSeller_Coupon = new Map<String, String>{
        'Coupon__c' => 'Id'
   	};
    private static Map<String, String> mRT_Coupon_CouponSeller = new Map<String, String>{
        'Item_Based' => 'Manhattan_Coupon',
        'Category_Based' => 'Manhattan_Coupon',
        'Pop_Coupon' => 'Pop_Coupon',
        'Single_Contract_Multi_Coupon_SCMC_Category_Based' => 'Master_Agreement_Seller', // US 0033050
        'Program_Coupon' => 'Program_Coupon_Seller' // US-0033151
    };
        
    @AuraEnabled
    public static Map<String, Object> doGetCoupon(String recordId) {
        Map<String, Object> mResult = new Map<String, Object>();

        try{
            String queryStr = 'SELECT RecordType.DeveloperName,'+ String.join((Iterable<String>)mCouponSeller_Coupon.values(), ',') +' FROM Coupon__c WHERE Id =: recordId';
            Coupon__c oCoupon = Database.query(queryStr);
            Map<String, Object> mField = new Map<String, Object>();
            for(String cSellerField : mCouponSeller_Coupon.keySet()){
                Object val = oCoupon.get(mCouponSeller_Coupon.get(cSellerField));
                if(val == null) continue;
                mField.put(cSellerField, val);
            }
            // Set default couponSeller recordtype by coupon
            String cSellerRT = mRT_Coupon_CouponSeller.get(''+oCoupon.getSObject('RecordType').get('DeveloperName'));
            mResult.put('recordTypeId', ApexUtil.getRecordTypeByName('Coupon_Seller__c', cSellerRT).Id);
            mResult.put('params', mField);

            mResult.put('isSuccess', true);
        } catch (Exception ex) {
            mResult.put('isSuccess', false);
            mResult.put('msg', ex.getMessage());
        }

        return mResult;
    }
        

}