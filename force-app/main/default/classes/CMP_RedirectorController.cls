/*****************************************************************************************************************************
    @ Calss:   CMP_RedirectorController
    @ Version:  1.0
    @ Author:   Vadhanak Voun
    @ Purpose: Controller fro vf page CMP_Redirector
     ------------------------------------------------------------------------------------------------------------------------------    
    @ Change history: 09/07/2020 / Vadhanak Voun / US-0007824 - EU Advertising CPM Calculator
    *****************************************************************************************************************************/
public without sharing class CMP_RedirectorController {
    public String selectedItems{get;set;}
    public CMP_RedirectorController(ApexPages.StandardSetController items) 
    {
        List<String> listItem = new List<String>();
        for ( SObject sobj : items.getSelected() )
        {
            listItem.add(sobj.Id);
        }
        selectedItems = String.join(listItem, ',');
    }
    
}