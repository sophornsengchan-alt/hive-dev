/*********************************************************************************************************************************
    @ Class:         menusController
    @ Purpose:       US-0013379 - Rework to Useful Links
    @ git Repo:      https://github.com/salesforce-experiencecloud/MultiLevelNavigationMenu
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.10.2023 / Mony Nou / Created the class.
*********************************************************************************************************************************/
global class menusPicklist extends VisualEditor.DynamicPickList {
    VisualEditor.DesignTimePageContext context;
    
    global menusPicklist(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }
    
    global override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DynamicPickListRows rowList =  getPicklistRows();
        if(rowList.size() > 0) 
        {
            return rowList.get(0);
        }

        return null;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        return getPicklistRows();
    }

    private static VisualEditor.DynamicPickListRows getPicklistRows() {

        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        VisualEditor.DataRow value2 = new VisualEditor.DataRow('[Name Filter]','nameFilter');
        myValues.addRow(value2);
        
        for(Menu__c menu : [SELECT Id, Name FROM Menu__c ORDER BY Name LIMIT 100])
        {
            VisualEditor.DataRow value = new VisualEditor.DataRow(menu.Name, menu.Id + '');
            myValues.addRow(value);
        }
        
        return myValues;

    }

}