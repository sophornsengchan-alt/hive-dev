/*********************************************************************************************************************************
@ Class:          CouponBCDFileDownloadController
@ Version:        1.0
@ Author:         
@ Purpose:        Controller Class for BCD Coupon download button
@                  EPH-7723 Coupon Object - csv file + download functionality for BCD
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23/07/2019 / Created the class.
@				: 15.11.2019/ used shared method buildCSVData from CouponTriggerHandler
*********************************************************************************************************************************/
public with sharing class CouponBCDFileDownloadController {
	public string couponId {get;set;}
	public String csvData{get;set;}
	public CouponBCDFileDownloadController(ApexPages.StandardController controller) {
		 couponId = controller.getRecord().id;
		 Map<String,String> mapRsult = CouponTriggerHandler.buildCSVData(new Set<String>{couponId});
		 csvData = mapRsult.get(couponId);
	}
    
}