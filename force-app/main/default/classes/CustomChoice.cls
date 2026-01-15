/*********************************************************************************************************************************
@ Class:         CustomChoice
@ Version:       1.0
@ Author:        vadhanak.vounr (vadhanak.voun@gaea-sys.com)
@ Purpose:       For used in Screen Flow choice component that allow customimze the label. Standard Choice class only support value field. Not manipulate label field.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.11.2025 / vadhanank voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public with sharing class CustomChoice {
  public CustomChoice(){}
  
    @AuraEnabled
    public String label; //AuraEnabled fields require at least one of the following global, public
  
    @AuraEnabled
    public String value;
  
    public CustomChoice(String label, String value) {
      this.label = label;
      this.value = value;
    }
  }