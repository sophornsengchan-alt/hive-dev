/*********************************************************************************************************************************
@ Component:    LwcCustomDatatable
@ Purpose : Custom component that extends LightningDatatable and adds a new column type
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: US-0013300 - Missing Validation Rule in Bulk Upload Coupon Seller Component
@               : 05.11.2024 / Sovantheany Dim / US-0016104 - customPicklist for Initiate call
@               : 03.04.2025 / Sothea Horn / US-0017049 - Validate Linkage and capture first call feedback
@               : 19.05.2025 / Sothea Horn / US-0012817 - Update Linked Customer View
*********************************************************************************************************************************/
import LightningDatatable from 'lightning/datatable';
import customRichTextTemplate from "./lwcCustomRichtext.html";
import customPicklistTemplate from "./lwcCustomPicklist.html";
import pickliststaticTemplate from "./lwcPicklistStatic.html";
import lookupTemplate from './lookup.html';
export default class LwcCustomDatatable extends LightningDatatable {
    static customTypes = {
        richText: {
            template: customRichTextTemplate,
            standardCellLayout: true,
        },
        //03.04.2025 / Sothea Horn / inline picklist editing when clicking pecil icon on each cell (US-0017049)
        customPicklist: {
            template: pickliststaticTemplate,
            editTemplate: customPicklistTemplate,
            standardCellLayout: true,
            typeAttributes : ['options', 'disabled', 'value', 'label']
        },
        //19.05.2025 / Sothea Horn / inline lookup editing when clicking pecil icon on each cell (US-0012817)
        lookup: {
            template: lookupTemplate,
            standardCellLayout: true,
            typeAttributes: ['value', 'object', 'lookupField', 'nameField', 'context', 'editable', 'filter', 'customViewLookupRecord']
        }
    }
}