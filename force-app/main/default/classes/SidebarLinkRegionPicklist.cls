/*****************************************************************************************************************************
@ Class:        SidebarLinkRegionPicklist
@ Version:      1.0
@Author:        Sambath Seng (sambath.seng@gaea-sys.com)
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18-3-2022 / Sambath Seng / US-0011390 - Refactor Useful Links for new Permission Model
*****************************************************************************************************************************/
global class SidebarLinkRegionPicklist extends VisualEditor.DynamicPickList{
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('', '');
        return defaultValue;
    }

    global override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
       
		Schema.DescribeFieldResult fields = Sidebar_Card__mdt.Region__c.getDescribe();
		List<Schema.PicklistEntry> fieldValues = fields.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : fieldValues){		

            myValues.addRow(new VisualEditor.DataRow(pickListVal.getLabel(), pickListVal.getValue()));
		}     
		
        return myValues;
    }
}