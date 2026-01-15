/**
 * @description 
 * @date        09/09/2021
 * @author      Samnang MUONG
 */
global class SitePickList extends VisualEditor.DynamicPickList{
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('', '');
        return defaultValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();

        myValues.addRow(new VisualEditor.DataRow('--None--', ''));
       
		Schema.DescribeFieldResult fieldResult = EBH_DealRetailCampaign__c.EBH_Country__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){		

            myValues.addRow(new VisualEditor.DataRow(pickListVal.getLabel(), pickListVal.getValue()));
		}     
		
        return myValues;
    }
}